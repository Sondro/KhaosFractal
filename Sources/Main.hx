package;

import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.input.KeyCode;
import kha.compute.Compute;
import kha.compute.ConstantLocation;
import kha.compute.Shader;
import kha.compute.TextureUnit;
import kha.compute.Access;
import kha.graphics4.FragmentShader;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureFormat;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.Shaders;
import kha.System;
import kha.math.Vector4;
import kha.math.FastMatrix3;
import kha.math.FastMatrix4;

class Main {
	private static var pipeline: PipelineState;
	private static var vertices: VertexBuffer;
	private static var indices: IndexBuffer;
	private static var texture: Image;
	private static var texunit: kha.graphics4.TextureUnit;
	private static var offsets: kha.compute.ConstantLocation;
	private static var computeTexunit: kha.compute.TextureUnit;
	private static var origin:Vector4;
	private static var forward:Bool;
	private static var limit:Float;
	private static var WIDTH:Int = 1024;
	private static var HEIGHT:Int = 768;
	
	public static function main(): Void {
		System.start({title: "ComputeShader", width: WIDTH, height: 768}, function (win:kha.Window) {
			texture = Image.create(WIDTH, HEIGHT, TextureFormat.RGBA64);
			
			computeTexunit = Shaders.test_comp.getTextureUnit("destTex");
			offsets = Shaders.test_comp.getConstantLocation("origin");
			
			var structure = new VertexStructure();
			structure.add("pos", VertexData.Float3);
			structure.add("tex", VertexData.Float2);
			
			pipeline = new PipelineState();
			pipeline.inputLayout = [structure];
			pipeline.vertexShader = Shaders.shader_vert;
			pipeline.fragmentShader = Shaders.shader_frag;
			pipeline.compile();
			
			texunit = pipeline.getTextureUnit("texsampler");

			vertices = new VertexBuffer(4, structure, Usage.StaticUsage);
			var v = vertices.lock();
			v.set(0, -1.0); v.set(1, -1.0); v.set(2, 0.5); v.set(3, 0.0); v.set(4, 1.0);
			v.set(5, 1.0); v.set(6, -1.0); v.set(7, 0.5); v.set(8, 1.0); v.set(9, 1.0);
			v.set(10, -1.0); v.set(11, 1.0); v.set(12, 0.5); v.set(13, 0.0); v.set(14, 0.0);
			v.set(15, 1.0); v.set(16, 1.0); v.set(17, 0.5); v.set(18, 1.0); v.set(19, 0.0);

			vertices.unlock();
			
			indices = new IndexBuffer(6, Usage.StaticUsage);
			var i = indices.lock();
			i[0] = 0; i[1] = 1; i[2] = 2;
			i[3] = 1; i[4] = 3; i[5] = 2;
			indices.unlock();
			
			origin = new Vector4(0.0, 0.4, 3.0, 1.0);
			limit = 8.0;
			forward = true;
			System.notifyOnFrames(render);
			Keyboard.get().notify(onKeyDown, null, null);
			Mouse.get().notify(null, null, null, onWheel);
		});
	}

	private static function render(frame: Array<Framebuffer>): Void {
		var g = frame[0].g4;
		g.begin();
		g.clear(Color.Black);
		
		Compute.setShader(Shaders.test_comp);
		Compute.setTexture(computeTexunit, texture, Access.Write); // destTex
		origin.w += (forward ? 0.002 : -0.002); 
		Compute.setFloat4(offsets, origin.x, origin.y, origin.z, origin.w);
		Compute.compute(texture.width, texture.height, 1);
		
		g.setPipeline(pipeline);
		g.setTexture(texunit, texture);
		g.setVertexBuffer(vertices);
		g.setIndexBuffer(indices);
		g.drawIndexedVertices();
		
		g.end();
		if (origin.w > limit || origin.w < 1.0) forward = !forward;
	}

    static function onWheel(wheel:Int) {
    	origin.z *= wheel > 0.0 ? 0.95 : 1.05;
    }

    static function onKeyDown(key:Int) {
		var move:Float = 0.005 * origin.z;
        if (key == KeyCode.Up) origin.y -= move;
        else if (key == KeyCode.Down) origin.y += move;
        else if (key == KeyCode.Left) origin.x -= move;
        else if (key == KeyCode.Right) origin.x += move;
    }
}
