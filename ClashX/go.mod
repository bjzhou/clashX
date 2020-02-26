module github.com/yichengchen/clashX/ClashX

replace github.com/Dreamacro/clash => ./clash

require (
	github.com/Dreamacro/clash v1.0.0
	github.com/phayes/freeport v0.0.0-20180830031419-95f893ade6f2
)

go 1.13
