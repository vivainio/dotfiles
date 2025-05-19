# kvx module

# Yeah I forked it from kv.nu to hide my stuff from 'kv list'


def _get_table_name [
  --hidden (-h)  # Whether to use the hidden db
] {
  if ($hidden) {
    'std_kv_store_hidden'
  } else {
    'std_kv_store'
  }
}

# If the key already exists, it is updated to the new value provided.
@example "Store the list of files in the home directory" {
  ls ~ | kvx set "home snapshot"
}
@example "Store a number" {
  kvx set foo 5
}
@example "Update a number" {
  kvx set foo { $in + 1 }
}
export def "kvx set" [
  key: string
  value_or_closure?: any
  --return (-r): string   # Whether and what to return to the pipeline output
  --universal (-u)        # Store the key-value pair in a universal database
  --hidden (-h)        # Store the key-value pair in a hidden database (kv list doesn't show the values)
] {
  # Pipeline input is preferred, but prioritize
  # parameter if present. This allows $in to be
  # used in the parameter if needed.
  let input = $in

  # If passed a closure, execute it
  let arg_type = ($value_or_closure | describe)
  let value = match $arg_type {
    closure => { $input | do $value_or_closure }
    _ => ($value_or_closure | default $input)
  }

  # Store values as nuons for type-integrity
  let kv_pair = {
    session: ''   # Placeholder
    key: $key
    value: ($value | to nuon)
  }

  let table_name = _get_table_name --hidden=$hidden
  let db_open = (db_setup --universal=$universal --hidden=$hidden)
  try {
    # Delete the existing key if it does exist
    do $db_open | query db "DELETE FROM std_kv_store WHERE key = :key" --params { key: $key }
  }

  let table_name = if ($hidden) {
    'std_kv_store_hidden'
  } else {
    'std_kv_store'
  }

  match $universal {
    true  => { $kv_pair | into sqlite (universal_db_path) -t std_kv_store }
    false => { $kv_pair | stor insert -t $table_name }
  }

  # The value that should be returned from `kvx set`
  # By default, this is the input to `kvx set`, even if
  # overridden by a positional parameter.
  # This can also be:
  # input: (Default) The pipeline input to `kvx set`, even if
  #        overridden by a positional parameter. `null` if no
  #        pipeline input was used.
  # ---
  # value: If a positional parameter was used for the value, then
  #        return it, otherwise return the input (whatever was set).
  #        If the positional was a closure, return the result of the
  #        closure on the pipeline input.
  # ---
  # all: The entire contents of the existing kvx table are returned
  match ($return | default 'input') {
    'all' => (kvx list --universal=$universal)
    'a' => (kvx list --universal=$universal)
    'value' => $value
    'v' => $value
    'input' => $input
    'in' => $input
    'i' => $input
    _  => {
      error make {
        msg: "Invalid --return option"
        label: {
          text: "Must be 'all'/'a', 'value'/'v', or 'input'/'in'/'i'"
          span: (metadata $return).span
        }
      }
    }
  }
}

# Retrieves a stored value by key
#
# Counterpart of "kvx set". Returns null if the key is not found.
@example "Retrieve a stored value" {
  kvx get foo
}
export def "kvx get" [
  key: string       # Key of the kv-pair to retrieve
  --universal (-u)  # Whether to use the universal db
  --hidden (-h)     # Whether to use the hidden db
] {
  let db_open = (db_setup --universal=$universal --hidden=$hidden)
  let table_name = _get_table_name --hidden=$hidden
  do $db_open
    # Hack to turn a SQLiteDatabase into a table
    | $in | get $table_name | wrap temp | get temp
    | where key == $key
    # Should only be one occurrence of each key in the stor
    | get -i value.0
    | match $in {
      # Key not found
      null => null
      # Key found
      _ => { from nuon }
    }
}

# List the currently stored key-value pairs
#
# Returns results as the Nushell value rather than the stored nuon.
export def "kvx list" [
  --universal (-u)  # Whether to use the universal db
] {
  let db_open = (db_setup --universal=$universal)

  do $db_open | $in.std_kv_store? | each {|kv_pair|
    {
      key: $kv_pair.key
      value: ($kv_pair.value | from nuon )
    }
  }
}

# Returns and removes a key-value pair
export def --env "kvx drop" [
  key: string       # Key of the kv-pair to drop
  --universal (-u)  # Whether to use the universal db
  --hidden (-h)     # Whether to use the hidden db
] {
  let db_open = (db_setup --universal=$universal --hidden=$hidden)

  let value = (kvx get --universal=$universal $key)
  let table_name = _get_table_name --hidden=$hidden

  try {
    do $db_open
      # Hack to turn a SQLiteDatabase into a table
      | query db $"DELETE FROM ($table_name) WHERE key = :key" --params { key: $key }
  }

  if $universal and ($env.NU_KV_UNIVERSALS? | default false) {
    hide-env $key
  }

  $value
}

def universal_db_path [] {
  $env.NU_UNIVERSAL_KV_PATH?
  | default (
    $nu.data-dir | path join "std_kv_variables.sqlite3"
  )
}

def db_setup [
  --universal   # Whether to use the universal db
  --hidden      # Whether to use the hidden db
] : nothing -> closure {
  try {
    match $universal {
      true  => {
        # Ensure universal sqlite db and table exists
        let uuid = (random uuid)
        let dummy_record = {
          session: ''
          key: $uuid
          value: ''
        }
        $dummy_record | into sqlite (universal_db_path) -t std_kv_store
        open (universal_db_path) | query db "DELETE FROM std_kv_store WHERE key = :key" --params { key: $uuid }
      }
      false => {
        let table_name = if ($hidden) {
          'std_kv_store_hidden'
        } else {
          'std_kv_store'
        }
        # Create the stor table if it doesn't exist
        stor create -t $table_name -c {session: str, key: str, value: str} | ignore
      }
    }
  }

  # Return the correct closure for opening on-disk vs. in-memory
  match $universal {
    true  => {{|| open (universal_db_path)}}
    false => {{|| stor open}}
  }
}

# This hook can be added to $env.config.hooks.pre_execution to enable
# "universal variables" similar to the Fish shell. Adding, changing, or
# removing a universal variable will immediately update the corresponding
# environment variable in all running Nushell sessions.
export def "kvx universal-variable-hook" [] {
{||
  kvx list --universal
  | transpose -dr
  | load-env

  $env.NU_KV_UNIVERSALS = true
}
}
