import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/group_order.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/widgets/group_tile_widget.dart';
import 'package:rankmyroast/services/sqlite_helper.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  late Future<List<Group>> _groups;

  @override
  void initState() {
    _groups = _fetchGroups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder(
            future: _groups,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Groups",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "No active groups found",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                    IconButton(
                      onPressed: createGroup,
                      icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          side: BorderSide(color: Colors.transparent, width: 1),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox();
              } else {
                return Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Groups ",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "${snapshot.data!.length} group(s) found",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 2),
                            GestureDetector(
                              onTap:
                                  () => setState(() {
                                    _groups = _fetchGroups();
                                  }),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                    IconButton(
                      onPressed: createGroup,
                      icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          side: BorderSide(color: Colors.transparent, width: 1),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 16.h),
          FutureBuilder(
            future: _groups,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 220.h),
                    Center(
                      child: Text(
                        "Create your first group.",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ElevatedButton(
                      onPressed: createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        maximumSize: Size(100.w, 40.h),
                        minimumSize: Size(100.w, 40.h),
                      ),
                      child: Text(
                        "Create Group",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              } else {
                final groups = snapshot.data!;
                return Expanded(
                  child: SizedBox(
                    child: ReorderableListView.builder(
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final movedRecipe = groups.removeAt(oldIndex);
                        groups.insert(newIndex, movedRecipe);
                        setState(() {});
                        _upsertGroupOrder(groups);
                      },
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        // Pull the single source of truth from your synchronized local list
                        final currentGroup = groups.elementAt(index);

                        return ReorderableDragStartListener(
                          index: index,
                          // Add the key here to satisfy ReorderableDragStartListener requirements...
                          key: ValueKey(currentGroup.id),
                          child: GroupTileWidget(
                            // CRITICAL FIX: Put the same key explicitly on your custom widget,
                            // and pass the group data from the synchronized 'groups' list, NOT the snapshot.
                            key: ValueKey(currentGroup.id),
                            group: currentGroup,
                            editGroupCallback: editGroupCallback,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void createGroup() async {
    final refresh = await context.push("/base/create-group");

    if (refresh == true) {
      setState(() {
        _groups = _fetchGroups();
      });
    }
  }

  void editGroupCallback() {
    setState(() {
      _groups = _fetchGroups();
    });
  }

  Future<List<Group>> _fetchGroups() async {
    final groups = await SupabaseHelper.groups.getGroupsForUser();

    if (groups == null) {
      return [];
    }

    final sqliteHelper = SqliteHelper();
    final groupOrders = await sqliteHelper.getGroupOrders();

    late final List<Group> newGroups;

    if (sqliteHelper.pastGroupsContainsCurrentGroups(groups, groupOrders)) {
      newGroups =
          groupOrders
              .map(
                (order) =>
                    groups.firstWhere((group) => group.id == order.groupId),
              )
              .toList();
    } else {
      newGroups =
          groupOrders
              .map(
                (order) =>
                    groups.firstWhere((group) => group.id == order.groupId),
              )
              .toList();
      newGroups.addAll(groups.where((group) => !newGroups.contains(group)));
    }

    return newGroups;
  }

  Future<void> _upsertGroupOrder(List<Group> groups) async {
    final List<Map<int, String>> groupOrder = [];
    final sqliteHelper = SqliteHelper();

    for (final item in groups.indexed) {
      final index = item.$1;
      final group = item.$2;

      groupOrder.add({index: group.id});
    }

    await sqliteHelper.upsertGroupOrder(groupOrder);
  }
}
