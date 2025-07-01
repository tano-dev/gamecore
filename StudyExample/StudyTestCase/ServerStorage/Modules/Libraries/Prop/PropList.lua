export type Prop = {
	Instance: Model,
	Config: any,
	Root: BasePart,
	Origin: CFrame,
	Respawn: (Prop) -> (),
	MaxHealth: number,
	Health: number,
	PlayerTags: {},
}

return {}