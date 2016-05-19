using LTspice, Base.Test

test9 = LTspiceSimulation("test9.asc","")

mv = measurementvalues(test9)[:,:,1,1]
mv_expected = [-0.5 0.0 0.5; -1.0 NaN 1.0; 1.0 NaN -1.0]
@test_approx_eq mv mv_expected
