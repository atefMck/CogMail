-- Utility functions for responsive sizing
local Utils = {}

-- Get terminal size
function Utils.getTerminalSize()
    local termObj = term.current()
    if termObj and termObj.getSize then
        return termObj.getSize()
    end
    -- Fallback to default size if term.current() doesn't work
    return 51, 19
end

-- Calculate responsive positions and sizes
function Utils.getResponsiveLayout()
    local width, height = Utils.getTerminalSize()
    
    return {
        width = width,
        height = height,
        -- Common spacing
        margin = 2,
        -- Button dimensions
        buttonHeight = math.max(1, math.floor(height / 15)),
        buttonWidth = math.max(10, math.floor(width / 3)),
        -- Input dimensions
        inputWidth = math.max(20, width - 4),
        inputHeight = 1,
        -- Label spacing
        labelSpacing = math.max(2, math.floor(height / 12)),
        -- Status label position
        statusY = math.max(10, height - 5),
        -- Button row position
        buttonY = math.max(12, height - 3)
    }
end

return Utils

