using LTspice, Base.Test

test10 = LTspiceSimulation("test10.asc","")
@test test10["m1"] == 0.0
@test isnan(test10["bad_meas"])
