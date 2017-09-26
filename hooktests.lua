local file1, file2 = "linkedhooks.lua", "dashhook.lua"

print("testing "..file1)
local score1 = include "hooksuite.lua":All(include(file1))

print("testing "..file2)
local score2 = include "hooksuite.lua":All(include(file2))

print "\n\n\n\n\n\n\n\n"
print "BENCHMARK"

for k, v in pairs(score2) do
    if (not v.Time) then continue end

    local did2win = (score1[k].Time > v.Time)
    print '-------------'

    print(string.format("Winner: %s (%.02f%%) - %s", did2win and file2 or file1, 100 * (1 - (did2win and  score1[k].Time / v.Time or v.Time / score1[k].Time)), k))
    print(string.format("Score %s: %.09f", file2, v.Time))
    print(string.format("Score %s: %.09f", file1, score1[k].Time))
end
print "-------------"