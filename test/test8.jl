using LTspice
using Base.Test

test8file = "test8.asc"
exc = ""
test8 = LTspiceSimulation!(test8file,exc)
show(test8)
show(test8.circuit)
show(test8.log)

@test test8["a@"] == 1.0
@test test8["b#"] == 2.0
@test test8["c\$"] ==3.0
@test test8["d."] == 4.0
@test test8["e:"] == 5.0
# @test test8["j\\\\"] == 10.0  # Giving up on support of \
@test test8["a@m"] == 1.0
@test test8["b#m"] == 2.0
@test test8["c\$m"] == 3.0
@test test8["e:m"] == 5.0
# @test test8["j\\\\m"] == 10.0 # giving up on support of \
@test test8["voltage"] == -4.0
