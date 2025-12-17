import 'dart:ui';

class GlMaterial {
  final Color ambient;
  final Color diffuse;
  final Color specular;
  final double shininess;
  GlMaterial(this.ambient, this.diffuse, this.specular, this.shininess);
}

class MaterialList {

  final Map<String, GlMaterial> materials = {};
  GlMaterial getMaterial(String name) {
    if (!materials.containsKey(name)) {
      return materials['default']!;
    }
    return materials[name]!;
  }

  void addMaterial(String name, GlMaterial material) {
    materials[name] = material;
  }

  void setDefaultMaterial(GlMaterial material) {
    materials['default'] = material;
  }

}