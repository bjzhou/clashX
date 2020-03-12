module github.com/yichengchen/clashX/ClashX

replace github.com/bjzhou/clash => ./clash

require (
	github.com/bjzhou/clash v0.18.0-pre
	github.com/brobird/gossr v0.0.0-20200301124130-51310d37cfeb // indirect
	github.com/phayes/freeport v0.0.0-20180830031419-95f893ade6f2
	gitlab.com/yawning/chacha20.git v0.0.0-20190903091407-6d1cb28dc72c // indirect
)

go 1.13
