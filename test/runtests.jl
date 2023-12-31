using SealDb
using Test

@testset "Brexanolone" begin
	session = "1149-001-01"
	@test get_structural_series(session, "t1w") == [10]
	@test get_structural_series(session, "t2w") == [14]
	@test get_fieldmap_series(session, "j") == [15, 21]
	@test get_fieldmap_series(session, "j-") == [16, 22]
	@test get_functional_series(session) == [17, 24]

	all_series = get_series("WHERE session = '$session'")
	acq_times = get_acq_time.(session, all_series)
	@test all(diff(acq_times) .>= Nanosecond(0))
	acq_times2 = get_acq_times("WHERE session = '$session'")
	@test acq_times == acq_times2

	meta = get_functional_run_metadata(Dict(:session => session))
	@test collect(keys(meta)) == [17, 24]
	@test meta[17] == meta[24]
	@test meta[17]["echo_type"] == "se"
	@test meta[17]["nx"] == 90
	@test meta[17]["ped"] == "j"
	@test meta[17]["mbfac"] == 6
	@test meta[17]["acq_res"] == 2.4
end

