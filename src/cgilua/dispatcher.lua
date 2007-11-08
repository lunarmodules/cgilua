module(..., package.seeall)


-- Checks if a URL matches a route pattern
local function route_match(url, pattern) 
    local params = {}
    local captures = string.gsub(pattern, "(/$[%w_-]+)", "/?([^/]*)")
    local url_parts = {string.match(url, captures)}
    local i = 1
    for name in string.gmatch(pattern, "/$([%w_-]+)") do
        params[name] = url_parts[i]
        i = i + 1
    end
    return next(params) and params
end

local route_URLs = {}

-- Maps the correct function for a URL
local function route_map(url) 
    for i, v in ipairs(route_URLs) do
        local pattern, f, name = unpack(v)
        local params = route_match(url, pattern)
        if params then 
            return f, params 
        end
    end
end

-- Returns a URL for a route
function route_url(action_name, params)
    for i, v in ipairs(route_URLs) do
        local pattern, f, name = unpack(v)
        if name == action_name then
            local url = string.gsub(pattern, "$([%w_-]+)", params)
            url = cgilua.urlpath.."/"..cgilua.app_name..url
            return url
        end
    end
end

-- Defines the routing using a table of URLs
function route(URLs)
    route_URLs = URLs
    f, args = route_map(cgilua.script_vpath)

    if f then
        return true, function() f(args) end
    else
        error("Missing page parameters")
    end
end