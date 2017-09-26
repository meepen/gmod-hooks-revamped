local file1, file2 = "linkedhooks.lua", "dashhook.lua"

print("testing "..file1)
local score1 = include "hooksuite.lua":All(include(file1))

print("testing "..file2)
local score2 = include "hooksuite.lua":All(include(file2))

print "\n\n\n\n\n\n\n\n"
print "BENCHMARK"

local printafter1 = (" "):rep(math.max(file1:len(), file2:len()) - file1:len())
local printafter2 = (" "):rep(math.max(file1:len(), file2:len()) - file2:len())

for k, v in pairs(score2) do
    if (not v.Time) then continue end

    local did2win = (score1[k].Time > v.Time)
    print '-------------'

    print(string.format("%s (%i calls)\n%s (%.02f%%)", k, v.Calls or 0, did2win and file2 or file1, 100 * (1 - (did2win and  score1[k].Time / v.Time or v.Time / score1[k].Time))))
    print(string.format("%s:%s %.09f s", file2, printafter2, v.Time))
    print(string.format("%s:%s %.09f s", file1, printafter1, score1[k].Time))
end
print "-------------"