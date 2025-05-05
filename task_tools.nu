
def find-up [filename: string] {
  mut dir = $env.PWD

  loop {
    let candidate = ($dir | path join $filename)
    if ($candidate | path exists) {
      return $candidate
    }

    let parent = ($dir | path dirname)
    if ($parent == $dir) {
      error make {
        msg: $"File not found in any parent directory: ($filename)"
      }
    }

    $dir = $parent
  }
}
# Run tasks.py in current directory or parent directory
# If a virtual environment is found, uv will be used to run the script
# Otherwise, it will run with the system Python
def pt [...args] {
  let task_file = (find-up "tasks.py")
  let task_dir = ($task_file | path dirname)
  let venv_dir = ($task_dir | path join ".venv")

  cd $task_dir

  if ($venv_dir | path exists) {
    ^uv run tasks.py ...$args
  } else {
    ^python tasks.py ...$args
  }
}




