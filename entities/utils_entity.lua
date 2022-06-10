local function addExtras(animation, extras)
    extras = extras or {}
    for k, v in pairs(extras) do
        animation[k] = v
    end
    return animation
end

local function copyAndAdd(obj, extras)
    local result = {}
    for k, v in pairs(obj or {}) do
        result[k] = v
    end
    for k, v in pairs(extras or {}) do
        result[k] = v
    end
    return result
end

function animationFactory(baseConfig)
    return function(config)
        config = config or {}
        local hr_filename = baseConfig.filename, nil
        if config.filename ~= nil then
            hr_filename = config.filename
        end
        local filename = hr_filename:gsub("/hr-", "/")
        local height = baseConfig.height
        if config.height ~= nil then
            height = config.height
        end
        local width = baseConfig.width
        if config.width ~= nil then
            width = config.width
        end
        local shift = baseConfig.shift
        if config.shift ~= nil then
            shift = config.shift
        end
        local frames = baseConfig.frames
        if config.frames ~= nil then
            frames = config.frames
        end
        local frames_per_line = baseConfig.frames_per_line
        if config.frames_per_line ~= nil then
            frames_per_line = config.frames_per_line
        end
        local offset = baseConfig.offset
        if config.offset ~= nil then
            offset = config.offset
        end
        local extras = baseConfig.extras
        if config.extras ~= nil then
            extras = config.extras
        end

        if config.direction ~= nil then
            filename = filename:gsub("DIR", config.direction)
            hr_filename = hr_filename:gsub("DIR", config.direction)
        end
        local half_shift = nil
        if shift ~= nil then
            half_shift = { shift[1] / 2, shift[2] / 2 }
        end
        local half_offset = 0
        if offset ~= nil then
            half_offset = offset / 2
        end

        local result = addExtras({
            hr_version = addExtras({
                filename = hr_filename,
                height = height,
                width = width,
                scale = 0.5,
                shift = shift,
                priority = "high",
                frame_count = frames,
                line_length = frames_per_line,
                x = 0,
                y = offset
            }, extras),
            filename = filename,
            height = height / 2,
            width = width / 2,
            shift = half_shift,
            scale = 1,
            priority = "high",
            frame_count = frames,
            line_length = frames_per_line,
            x = 0,
            y = half_offset
        }, extras)

        if string.find(filename, "-shadow.png") then
            result = {
                layers = {
                    copyAndAdd(result, {
                        filename = filename:gsub("-shadow", ""),
                        hr_version = copyAndAdd(result.hr_version, {
                            filename = hr_filename:gsub("-shadow", ""),
                        }),
                    }),
                    copyAndAdd(result, {
                        draw_as_shadow = true,
                        hr_version = copyAndAdd(result.hr_version, { draw_as_shadow = true }),
                    }),
                },
            }
        end

        return result
    end
end