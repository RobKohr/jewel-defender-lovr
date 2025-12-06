return lovr.graphics.newShader([[
  out vec3 viewDirection;
  out vec3 normalView;
  
  vec4 lovrmain() {
    // Transform position to view space
    vec4 posView = ViewFromLocal * VertexPosition;
    // View direction is negative of position in view space (camera at origin)
    viewDirection = normalize(-posView.xyz);
    
    // Transform normal to view space
    normalView = normalize(mat3(ViewFromLocal) * VertexNormal);
    
    return DefaultPosition;
  }
]], [[
  in vec3 viewDirection;
  in vec3 normalView;
  
  vec4 lovrmain() {
    // Get the base color from the texture/material
    vec4 baseColor = Color * getPixel(ColorTexture, UV);
    
    Surface surface;
    initSurface(surface);
    
    // Ambient lighting
    vec3 ambient = vec3(0.5, 0.5, 0.5);
    
    // Directional light coming strongly from the side to create dramatic edge highlights
    vec3 lightDirection = normalize(vec3(1.0, 0.2, 0.3));
    vec4 lightColorAndBrightness = vec4(1.0, 1.0, 1.0, 4.0);
    float visibility = 1.0;
    
    // Calculate main lighting
    vec3 lighting = ambient + getLighting(surface, lightDirection, lightColorAndBrightness, visibility);
    
    // Rim lighting to highlight edges
    // Calculate rim factor (edges facing away from camera)
    float rimFactor = 1.0 - max(dot(viewDirection, normalView), 0.0);
    // Apply rim light more strongly on edges (power curve for sharper edge)
    rimFactor = pow(rimFactor, 2.0);
    vec3 rimLight = vec3(1.0, 1.0, 1.0) * rimFactor * 1.5;
    
    // Combine all lighting
    vec3 finalColor = baseColor.rgb * (lighting + rimLight);
    
    return vec4(finalColor, baseColor.a);
  }
]], {
  flags = {
    normalMap = false
  }
})

