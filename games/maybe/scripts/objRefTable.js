const C3 = self.C3;
self.C3_GetObjectRefTable = function () {
	return [
		C3.Plugins.Sprite,
		C3.Behaviors.scrollto,
		C3.Behaviors.bound,
		C3.Behaviors.Car,
		C3.Behaviors.solid,
		C3.Behaviors.Bullet,
		C3.Behaviors.Rotate,
		C3.Plugins.Shape3D,
		C3.Plugins.System.Cnds.OnLayoutStart,
		C3.Behaviors.Rotate.Acts.SetEnabled,
		C3.Behaviors.Bullet.Acts.SetEnabled,
		C3.Plugins.System.Cnds.Compare,
		C3.Plugins.Sprite.Exps.X,
		C3.Plugins.System.Cnds.TriggerOnce,
		C3.Plugins.System.Acts.Wait,
		C3.Behaviors.Rotate.Acts.SetSpeed,
		C3.Behaviors.Bullet.Acts.SetSpeed,
		C3.Plugins.Sprite.Exps.Y,
		C3.Plugins.Sprite.Cnds.OnCollision,
		C3.Behaviors.Car.Acts.SetAcceleration,
		C3.Behaviors.Car.Acts.SetSpeed,
		C3.Behaviors.Car.Acts.SetMaxSpeed,
		C3.Plugins.Sprite.Acts.Destroy
	];
};
self.C3_JsPropNameTable = [
	{дорога: 0},
	{СледитьЗа: 0},
	{ОграничитьСценой: 0},
	{Машина: 0},
	{автомобиль: 0},
	{Твердый: 0},
	{Пуля: 0},
	{Поворот: 0},
	{машинка1: 0},
	{машинка2: 0},
	{Спрайт: 0},
	{Спрайт2: 0},
	{дом: 0},
	{Твёрдый: 0},
	{"3DФигуры": 0},
	{Спрайт3: 0},
	{"3DФигуры2": 0},
	{"3DФигуры3": 0},
	{конистраБензинабуст: 0}
];

self.InstanceType = {
	дорога: class extends self.ISpriteInstance {},
	автомобиль: class extends self.ISpriteInstance {},
	машинка1: class extends self.ISpriteInstance {},
	машинка2: class extends self.ISpriteInstance {},
	Спрайт: class extends self.ISpriteInstance {},
	Спрайт2: class extends self.ISpriteInstance {},
	дом: class extends self.ISpriteInstance {},
	_3DФигуры: class extends self.I3DShapeInstance {},
	Спрайт3: class extends self.ISpriteInstance {},
	_3DФигуры2: class extends self.I3DShapeInstance {},
	_3DФигуры3: class extends self.I3DShapeInstance {},
	конистраБензинабуст: class extends self.ISpriteInstance {}
}