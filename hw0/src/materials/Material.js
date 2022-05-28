class Material {
    #flatten_uniforms;
    #flatten_attribs;
    #vsSrc;
    #fsSrc;
    // Uniforms is a map, attribs is a Array
    constructor(uniforms, attribs, vsSrc, fsSrc) {
        this.uniforms = uniforms; // 传递光的强度以及颜色
        this.attribs = attribs;
        this.#vsSrc = vsSrc; // 字符串 顶点着色器
        this.#fsSrc = fsSrc;  // 片段着色器
        
        this.#flatten_uniforms = ['uModelViewMatrix', 'uProjectionMatrix', 'uCameraPos', 'uLightPos']; // 矩阵  以及 摄像头点 灯光点
        for (let k in uniforms) {
            this.#flatten_uniforms.push(k); // 需要传递的点
        }
        this.#flatten_attribs = attribs;
    }

    setMeshAttribs(extraAttribs) {
        for (let i = 0; i < extraAttribs.length; i++) {
            this.#flatten_attribs.push(extraAttribs[i]);
        }
    }

    compile(gl) {
        return new Shader(gl, this.#vsSrc, this.#fsSrc,
            {
                uniforms: this.#flatten_uniforms,
                attribs: this.#flatten_attribs
            });
    }
}