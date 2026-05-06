if FORMAT ~= "docx" then
  return
end

local function has_codeblock(tbl)
  local found = false
  tbl:walk {
    CodeBlock = function() found = true end
  }
  return found
end

local function fix_row(row)
  for _, cell in ipairs(row.cells) do
    cell.alignment = pandoc.AlignLeft
  end
end

function Table(tbl)
  if not has_codeblock(tbl) then return nil end

  for i = 1, #tbl.colspecs do
    tbl.colspecs[i] = { pandoc.AlignLeft, tbl.colspecs[i][2] }
  end

  if tbl.head then
    for _, row in ipairs(tbl.head.rows) do fix_row(row) end
  end
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.head) do fix_row(row) end
    for _, row in ipairs(body.body) do fix_row(row) end
  end
  if tbl.foot then
    for _, row in ipairs(tbl.foot.rows) do fix_row(row) end
  end

  return tbl
end
