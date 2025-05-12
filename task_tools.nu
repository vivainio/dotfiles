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


def tasks_complete [] {
  let completions = run_tasks "--jsonhelp"
  if (not ($completions | str starts-with "{")) {
    return []
  }
  
  let tasks = $completions | from json | transpose value description
  $tasks
}

def run_tasks [
  ...args  #additional arguments to pass to the task
] {
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

# Run tasks.py in current directory or parent directory
# If a virtual environment is found, uv will be used to run the script
# Otherwise, it will run with the system Python
export def pt [
  task?: string@tasks_complete  #the task name
  ...args  #additional arguments to pass to the task
] {
  let all_args = [$task] ++ [args] | compact 
  run_tasks ...$all_args
}
