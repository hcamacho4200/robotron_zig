#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0; // The input texture
uniform vec4 newColor;      // The new color to set
out vec4 finalColor;

void main() {
    if (texture(texture0, fragTexCoord).a == 0.0) {
        discard;  
    }
    finalColor = newColor;
}

// #version 330

// in vec2 fragTexCoord;
// uniform sampler2D texture0;    // Input texture
// uniform vec2 pixelCoords[100]; // List of pixel coordinates
// uniform int numPixels;         // Number of pixels in the list
// uniform vec2 texSize;          // Size of texture
// uniform vec4 newColor;         // Color to set
// out vec4 finalColor;

// vec2 points[27] = vec2[27](
//     vec2(2, 7), vec2(3, 7), vec2(4, 7), vec2(5, 7), vec2(6, 7), vec2(7, 7), vec2(8, 7), vec2(9, 7), vec2(10, 7), vec2(11, 7),
//     vec2(1, 8), vec2(2, 8), vec2(3, 8), vec2(4, 8), vec2(5, 8), vec2(6, 8), vec2(7, 8), vec2(8, 8), vec2(9, 8), vec2(10, 8), vec2(11, 8),
//     vec2(12, 8),
//     vec2(13, 8),
//     vec2(14, 8),
//     vec2(15, 8),
//     vec2(16, 8),
//     vec2(17, 8)
// );

// void main() {
//     vec2 texSize = textureSize(texture0, 0);
//     vec2 currentPixel = floor(fragTexCoord * texSize);

//     for (int i = 0; i < 27; i++) {
//         if (currentPixel == points[i]) {
//             finalColor = newColor;
//             return;
//         }
//     }

//     finalColor = texture(texture0, fragTexCoord);
// }

