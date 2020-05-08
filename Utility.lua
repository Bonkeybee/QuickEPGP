QUICKEPGP.isMe = function(name)
  return name == UnitName("player")
end

QUICKEPGP.round = function(number, decimals)
  if (number == nil) then
    number = 0
  end
  if (decimals == nil) then
    decimals = 0
  end
  return (("%%.%df"):format(decimals)):format(number)
end

QUICKEPGP.getItemId = function(itemLink)
  if (itemLink) then
    return select(3, strfind(itemLink, ":(%d+):"))
  end
  return nil
end

QUICKEPGP.getCharacterString = function(level, class, name)
  if (name) then
    local str = ""
    if (level or class) then
      str = str.."("
    end
    if (level) then
      str = str..level
    end
    if (class) then
      str = str..strupper(strsub(class, 1, 4))
    end
    if (level or class) then
      str = str..") "
    end
    return str..name
  end
  return nil
end

QUICKEPGP.getSimpleCharacterName = function(name, tolower)
  local simpleName = strsplit("-", name)
  if (tolower) then
    simpleName = strlower(simpleName)
  end
  return simpleName
end

QUICKEPGP.error = function(str)
  print("|cFFFF0000"..str.."|r")
end
