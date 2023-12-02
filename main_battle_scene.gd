extends Node2D
var card_instantiate = preload("res://scenes/card_base.tscn")
var player = preload("res://scenes/player.tscn")

signal tap_setting_button 
# 用于调整手牌弧线和位置的变量
@export_category("Curves")
@export var spread_curve : Curve
@export var y_curve : Curve
@export var rotation_curve : Curve

var card_height = 275
# 选择的人物
var pos : String = ""
var card_in_preview : Node = null

func _ready():
	$Control/TopBar/PosName.text = pos
	# 设置手牌中点
	$Hand.position = Vector2(get_window().size.x / 2, get_window().size.y - 100) 
	add_card(8)
	fix_all_card_position()

func _physics_process(delta):
	pass

#发手牌
func add_card(num:int):
	for i in range(num):
		var card = card_instantiate.instantiate()
		card.end_touch.connect(mouse_end_touch_hand_card.bind(card))
		card.on_touch.connect(card_preview.bind(card))
		card.position.x = -1080
		$Hand.add_child(card)
		
# 预览卡牌
func card_preview(card: Node):
	self.card_in_preview = card
	fix_all_card_position()

# 鼠标从卡牌上移开
func mouse_end_touch_hand_card(card:Node):
	if is_card_in_preview(card):
		self.card_in_preview = null
		fix_all_card_position()
	
	
	
# 删除一张牌
func delete_card(index:int):
	var cards = $Hand.get_children()
	print(cards.size())
	if cards.size() > 0 :
		var target_card = cards[index]
		var remove_tween = target_card.create_tween().set_parallel(true)
		remove_tween.tween_property(target_card,"rotation",0,0.3)
		remove_tween.tween_property(target_card,"position",Vector2(self.get_window().size.x / 2,0),0.3).as_relative()
		await remove_tween.finished
		remove_tween.kill()
		target_card.queue_free()
		$Hand.remove_child(target_card)
		fix_all_card_position()
		

# 卡牌位置类
class CardPosition:
	# 添加 public 修饰符
	var position: Vector2
	var rotation: float
	# 添加 func 关键字
	func _init(position:Vector2,rotation:float):
		self.position = position
		self.rotation = rotation
		
# 计算手牌位置和偏移
func get_card_position(card:Node) -> CardPosition:
	var cards = $Hand.get_children()
	var hand_card_index = cards.find(card)
	var card_count = cards.size()
	var hand_radio = 0.5
	if card_count > 0  :
	# 将卡牌的hand_radio值做“归一化”处理，输出0...1的均值，无论有多少张卡
		if card_count == 1 :
			hand_radio = 0.5
		else:
			hand_radio = float(hand_card_index) / float($Hand.get_child_count() - 1)
	# 对每张卡片进行调整以形成扇形
		var x = spread_curve.sample(hand_radio) * card_count * 70
		var y = -y_curve.sample(hand_radio) * card_count * 10
		if is_card_in_preview(card):
			var preview_card_height = card_height * 1.618
			y = -(preview_card_height / 2 - 100)
		var rotation_fix =  rotation_curve.sample(hand_radio) * card_count * 0.05
		if is_card_in_preview(card):
			rotation_fix = 0
		if self.card_in_preview != null:
			var card_in_preview_index = $Hand.get_children().find(self.card_in_preview)
			var index_offset = abs(hand_card_index - card_in_preview_index)
			var base = 2  # 调整这个值以控制指数递减的速度
			var correction = 150 * pow(base, -index_offset)
			# 对预览卡牌两侧的卡做一个指数递减的横向偏移
			if card_in_preview_index > hand_card_index :
				x -= correction
			elif card_in_preview_index < hand_card_index :
				x += correction
			else:
				pass
	# 返回计算结果
		return CardPosition.new(Vector2(x,y),rotation_fix)
	else:
		return CardPosition.new(Vector2(0,0),0)
		
# 调整所有手牌到正确位置
func fix_all_card_position():
	for card in $Hand.get_children():
		fix_card_position(card)

# 调整单张手牌到正确位置
func fix_card_position(card:Node):
	var card_index = $Hand.get_children().find(card)
	var end_position = get_card_position(card)
	move_card_to_position(card,end_position)
	
# 调整单张手牌到某个位置
func move_card_to_position(card:Node,position:CardPosition):
	var tween = card.create_tween().set_parallel(true)
	tween.tween_property(card,"rotation",position.rotation,0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card,"position",position.position,0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card,"scale",Vector2(1,1),0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	card.z_index = 0
	if is_card_in_preview(card):
		card.z_index = 1
		tween.tween_property(card,"scale",Vector2(1.618,1.618),0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
func is_card_in_preview(card:Node) -> bool:
	return self.card_in_preview != null and card.get_instance_id() == self.card_in_preview.get_instance_id()
	


func _on_setting_button_pressed():
	tap_setting_button.emit()
	pass # Replace with function body.


func _on_add_card_button_pressed():
	add_card(1)
	fix_all_card_position()

func _on_delete_card_button_pressed():
	delete_card(0)
