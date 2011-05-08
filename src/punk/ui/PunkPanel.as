package punk.ui
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Graphiclist;

	public class PunkPanel extends PunkUIComponent
	{
		public var graphiclist:Graphiclist;
		
		protected var buffer:BitmapData;
		protected var bounds:Rectangle;
		
		protected var _children:Vector.<PunkUIComponent> = new Vector.<PunkUIComponent>;
		protected var _count:int = 0;
		
		protected var oldX:Number = 0;
		protected var oldY:Number = 0;
		
		public function PunkPanel(x:Number=0, y:Number=0, width:int=20, height:int=20, background:Graphic = null)
		{
			if(width < 1) width = 1;
			if(height < 1) height = 1;
			
			super(x, y, width, height);
			
			oldX = x;
			oldY = y;
			
			buffer = new BitmapData(FP.width, FP.height, true, 0x00000000);
			bounds = new Rectangle(0, 0, width, height);
			
			graphic = graphiclist = new Graphiclist;
			if(background) graphiclist.add(background);
		}
		
		public function add(uiComponent:PunkUIComponent):PunkUIComponent
		{
			if(uiComponent is PunkPanel)
			{
				trace("PunkPanels can't contain other PunkPanels at the moment.");
				FP.log("PunkPanels can't contain other PunkPanels at the moment.");
				return uiComponent;
			}
			
			if(uiComponent._panel) return uiComponent;
			_children[_count++] = uiComponent;
			uiComponent._panel = this;
			uiComponent.x += x;
			uiComponent.y += y;
			if(_panel)
			{
				uiComponent.x -= _panel.relativeX;
				uiComponent.y -= _panel.relativeY;
			}
			uiComponent.added();
			return uiComponent;
		}
		
		public function remove(uiComponent:PunkUIComponent):PunkUIComponent
		{
			var index:int = _children.indexOf(uiComponent);
			if(index < 0) return uiComponent;
			_children.splice(index, 1);
			uiComponent.renderTarget = null;
			uiComponent.removed();
			uiComponent._panel = null;
			return uiComponent;
		}
		
		override public function update():void
		{
			super.update();
			
			var uiComponent:PunkUIComponent;
			for each(uiComponent in _children)
			{
				if(!uiComponent.active) continue;
				
				uiComponent.updateTweens();
				uiComponent.update();
				if(uiComponent.graphic && uiComponent.graphic.active) uiComponent.graphic.update();
			}
			
			if(oldX != x || oldY != y)
			{
				for each(uiComponent in _children)
				{
					uiComponent.x += x - oldX;
					uiComponent.y += y - oldY;
				}
			}
			
			bounds.width = width;
			bounds.height = height;
			
			oldX = x;
			oldY = y;
		}
		
		override public function render():void
		{
			super.render();
			
			buffer.fillRect(FP.bounds, 0x00000000);
			
			for each(var uiComponent:PunkUIComponent in _children)
			{
				if(!uiComponent.visible) continue;
				
				if(uiComponent._camera) uiComponent._camera.x = uiComponent._camera.y = 0;
				else uiComponent._camera = new Point;
				
				uiComponent.renderTarget = buffer;
				uiComponent.render();
			}
			
			FP.point.x = relativeX - FP.camera.x;
			FP.point.y = relativeY - FP.camera.y;
			
			bounds.x = x;
			bounds.y = y;
			
			var t:BitmapData = renderTarget ? renderTarget : FP.buffer;
			t.copyPixels(buffer, bounds, FP.point);
		}
		
		public function get children():Vector.<PunkUIComponent>
		{
			return _children;
		}
		
		public function get count():int
		{
			return _count
		}
		
		internal function get mouseX():int{ return _panel ? _panel.mouseX : world.mouseX; }
		internal function get mouseY():int{ return _panel ? _panel.mouseY : world.mouseY; }
		
		internal function frontCollidePoint(x:Number, y:Number):PunkUIComponent
		{
			var i:int = _children.length-1;
			var c:PunkUIComponent;
			for(;i > -1; --i)
			{
				c = _children[i];
				if(c.collidePoint(c.x, c.y, x, y)) return c;
			}
			return null;
		}
	}
}