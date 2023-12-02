extends Node2D

signal on_touch
signal end_touch

func _on_area_2d_mouse_entered():
	print("鼠标进入")
	#self.position.y = self.position.y - 200
	on_touch.emit()
	pass # Replace with function body.



func _on_area_2d_mouse_exited():
	end_touch.emit()
	pass # Replace with function body.
