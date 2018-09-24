# run this from test directory on a system with LTspice is_ltspice_installed
# to regenerate all of the test log files.

using LTspice

filelist = [
  "test1.asc",
  "test2.asc",
  "test3.asc",
  "test4.asc",
  "test5.asc",
  "test6.asc",
  "test7.asc",
  "test8.asc",
  "test9.asc",
  "test10.asc",
  "test11.asc",
  "test12.asc",
  "test13.asc",
  "test14.asc",
  "testinc1.asc",
  ]

for file in filelist
  sim = LTspiceSimulation(file)
  run!(sim)
end

#cp("test3.log","temp/test3.log", force=true)
