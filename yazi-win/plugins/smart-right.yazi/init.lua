return {
  entry = function()
    local hovered = cx.active.current.hovered
    if hovered and hovered.cha.is_dir then
      ya.manager_emit("enter", {})
    else
      ya.manager_emit("max_preview", {})
    end
  end,
}
