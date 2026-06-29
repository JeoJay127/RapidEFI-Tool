enum PatchAction {
  set,
  remove,
  replaceArray,
  mergeDict,
  appendArray,
}

class PatchOp {
  final PatchAction action;
  final List<String> path;
  final dynamic value;
  final bool createIfMissing;

  const PatchOp.set(
    this.path,
    this.value, {
    this.createIfMissing = true,
  }) : action = PatchAction.set;

  const PatchOp.remove(this.path)
      : action = PatchAction.remove,
        value = null,
        createIfMissing = false;

  const PatchOp.replaceArray(
    this.path,
    List<dynamic> this.value, {
    this.createIfMissing = true,
  }) : action = PatchAction.replaceArray;

  const PatchOp.mergeDict(
    this.path,
    Map<String, dynamic> this.value, {
    this.createIfMissing = true,
  }) : action = PatchAction.mergeDict;

  const PatchOp.appendArray(
    this.path,
    List<dynamic> this.value, {
    this.createIfMissing = true,
  }) : action = PatchAction.appendArray;
}
