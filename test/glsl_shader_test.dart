import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsg/glsl_shader.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'glsl_shader_test.mocks.dart';

// Simple valid GLSL shaders for testing.
const String kValidVertexShader = '''
  attribute vec4 a_position;
  uniform mat4 u_mvp_matrix;
  void main() {
    gl_Position = u_mvp_matrix * a_position;
  }
''';

const String kValidFragmentShader = '''
  void main() {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  }
''';

// Invalid GLSL shaders with syntax errors.
const String kInvalidVertexShader = '''
  attribute vec4 a_position;
  void main() {
    gl_Position = a_position // Missing semicolon
  }
''';

const String kInvalidFragmentShader = '''
  void main() {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0) // Missing semicolon
  }
''';

/// A helper class to mock the object returned by getProgramParameter,
/// which contains the ID we need to check.
class _MockWebGLParameter {
  final int id;
  _MockWebGLParameter(this.id);
}

@GenerateMocks([GlslShaderContext, Program, UniformLocation])
void main() {
  group('GlslShader', () {
    late MockGlslShaderContext mockGl;
    late MockProgram mockProgram;
    late Object mockVertexShader;
    late Object mockFragmentShader;
    late MockUniformLocation mockUniformLocation;

    setUp(() {
      mockGl = MockGlslShaderContext();
      mockProgram = MockProgram();
      mockVertexShader = Object();
      mockFragmentShader = Object();
      mockUniformLocation = MockUniformLocation();

      // Mock the standard successful GL call sequence
      when(mockGl.createShader(WebGL.VERTEX_SHADER))
          .thenReturn(mockVertexShader);
      when(mockGl.createShader(WebGL.FRAGMENT_SHADER))
          .thenReturn(mockFragmentShader);
      when(mockGl.shaderSource(any, any)).thenReturn(null);
      when(mockGl.compileShader(any)).thenReturn(null);
      when(mockGl.createProgram()).thenReturn(mockProgram);
      when(mockGl.attachShader(any, any)).thenReturn(null);
      when(mockGl.linkProgram(any)).thenReturn(null);

      // Correctly mock the different return types.
      when(mockGl.getProgramParameter(any, WebGL.LINK_STATUS))
          .thenReturn(_MockWebGLParameter(1)); // Returns a wrapper object
      when(mockGl.getShaderParameter(any, WebGL.COMPILE_STATUS))
          .thenReturn(true); // Returns a bool

      // Create and stub the MockUniformLocation.
      when(mockUniformLocation.id).thenReturn(0); // Default valid ID.
      when(mockGl.getAttribLocation(any, any))
          .thenReturn(mockUniformLocation);
      when(mockGl.getUniformLocation(any, any))
          .thenReturn(mockUniformLocation);

      when(mockGl.enableVertexAttribArray(any)).thenReturn(null);
      when(mockGl.checkError(any)).thenReturn(null);
      when(mockGl.deleteShader(any)).thenReturn(null);
      when(mockGl.deleteProgram(any)).thenReturn(null);
    });

    test('succeeds with valid shaders', () {
      expect(
        () => GlslShader(
          mockGl,
          kValidFragmentShader,
          kValidVertexShader,
          ['a_position'],
          ['u_mvp_matrix'],
        ),
        returnsNormally,
      );
    });

    test('correctly retrieves and caches attribute and uniform locations', () {
      final posLocation = MockUniformLocation();
      when(posLocation.id).thenReturn(1);
      final matrixLocation = MockUniformLocation();
      when(matrixLocation.id).thenReturn(5);

      when(mockGl.getAttribLocation(mockProgram, 'a_position'))
          .thenReturn(posLocation);
      when(mockGl.getUniformLocation(mockProgram, 'u_mvp_matrix'))
          .thenReturn(matrixLocation);

      final shader = GlslShader(
        mockGl,
        kValidFragmentShader,
        kValidVertexShader,
        ['a_position'],
        ['u_mvp_matrix'],
      );

      expect(shader.attributes['a_position'], 1);
      expect(shader.uniforms['u_mvp_matrix']!.id, 5);
    });

    test('throws and cleans up for invalid vertex shader', () {
      // Override the mock to return false for the vertex shader compilation.
      when(mockGl.getShaderParameter(mockVertexShader, WebGL.COMPILE_STATUS))
          .thenReturn(false);
      when(mockGl.getShaderInfoLog(mockVertexShader))
          .thenReturn('Vertex Compile Error');

      expect(
        () => GlslShader(
          mockGl,
          kValidFragmentShader,
          kInvalidVertexShader,
          [],
          [],
        ),
        throwsA(isA<Exception>()),
      );

      verify(mockGl.deleteShader(mockVertexShader)).called(1);
    });
  });
}
