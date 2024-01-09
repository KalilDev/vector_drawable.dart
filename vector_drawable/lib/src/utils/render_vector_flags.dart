int flagsFromSet(Set<RenderVectorCache> parts) {
  int result = 0;
  if (parts.contains(RenderVectorCache.clipPath)) {
    result |= ClipPathFlag;
  }
  if (parts.contains(RenderVectorCache.group)) {
    result |= GroupFlag;
  }
  if (parts.contains(RenderVectorCache.path)) {
    result |= PathFlag;
  }
  if (parts.contains(RenderVectorCache.childOutlet)) {
    result |= ChildOutletFlag;
  }
  if (parts.contains(RenderVectorCache.vector)) {
    result |= VectorFlag;
  }
  return result;
}

Set<RenderVectorCache> setFromFlags(int flags) => {
      if (cacheClipPath(flags)) RenderVectorCache.clipPath,
      if (cacheGroup(flags)) RenderVectorCache.group,
      if (cachePath(flags)) RenderVectorCache.path,
      if (cacheChildOutlet(flags)) RenderVectorCache.childOutlet,
      if (cacheVector(flags)) RenderVectorCache.vector,
    };
const int _false = 0;
const int _true = 1;
const int ClipPathFlag = _true << 0;
const int GroupFlag = _true << 1;
const int PathFlag = _true << 2;
const int ChildOutletFlag = _true << 3;
const int VectorFlag = _true << 4;
bool cacheClipPath(int cacheFlags) =>
    (cacheFlags & ClipPathFlag) == ClipPathFlag;
bool cacheGroup(int cacheFlags) => (cacheFlags & GroupFlag) == GroupFlag;
bool cachePath(int cacheFlags) => (cacheFlags & PathFlag) == PathFlag;
bool cacheChildOutlet(int cacheFlags) =>
    (cacheFlags & ChildOutletFlag) == ChildOutletFlag;
bool cacheVector(int cacheFlags) => (cacheFlags & VectorFlag) == VectorFlag;

enum RenderVectorCache {
  clipPath,
  group,
  path,
  childOutlet,
  vector,
}
