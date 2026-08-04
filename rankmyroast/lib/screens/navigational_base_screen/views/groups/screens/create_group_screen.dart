import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/snackbar_service.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/group_member.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/screens/widgets/delete_group_confirmation_dialog.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/screens/widgets/group_member_list_tile.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/screens/widgets/group_security_informational_dialog.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class CreateGroupScreen extends StatefulWidget {
  final Group? groupToEdit;

  const CreateGroupScreen({super.key, this.groupToEdit});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with SnackbarService {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  final List<GroupMember> _users = [];

  bool _isCreatingGroup = false;
  bool _isUsingRating = false;
  bool _showRatings = true;

  bool _canSubmit = false;

  late String _labelText;

  @override
  void initState() {
    if (widget.groupToEdit != null) {
      _groupNameController.text = widget.groupToEdit!.name;
      _isUsingRating = widget.groupToEdit!.useRating;
      _showRatings = widget.groupToEdit!.gradeVisible;
      _users.addAll(widget.groupToEdit!.groupMembers);
      _labelText = "Edit Group";
      _canSubmit = true;
    } else {
      _labelText = "Create Group";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,

        foregroundColor: Colors.white,
        title: Text(
          _labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.groupToEdit != null) ...[
            IconButton(
              onPressed: () async {
                final response = await _leaveGroup();
                if (response == true && context.mounted) {
                  context.pop(true);
                }
              },
              icon: Icon(Icons.exit_to_app, color: Colors.white),
            ),
            IconButton(
              onPressed: () async {
                final response = await _deleteGroup();
                if (response == true && context.mounted) {
                  context.pop(true);
                }
              },
              icon: Icon(Icons.delete, color: Colors.white),
            ),
          ],
        ],
      ),

      backgroundColor: Colors.green,

      body: Center(
        heightFactor: 1.15,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(115, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(2, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Group Name",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _groupNameController,
                        onChanged: (value) => _checkIfSubmitPossible(),
                        decoration: InputDecoration(
                          labelText: "Enter group name",
                          labelStyle: TextStyle(fontSize: 18),
                          floatingLabelBehavior: FloatingLabelBehavior.never,

                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      "Group Settings",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text("Show Rankings"),
                            activeColor: Colors.green,
                            subtitle: Text(
                              "Display recipe rankings to group members",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                            value: _showRatings,
                            onChanged: (value) {
                              setState(() {
                                _showRatings = value;
                              });
                            },
                          ),

                          SwitchListTile(
                            title: Text("Use Ratings"),
                            activeColor: Colors.green,
                            subtitle: Text(
                              "Use a rating system instead of a ranking system",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                            value: _isUsingRating,
                            onChanged: (value) {
                              setState(() {
                                _isUsingRating = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Group Members",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => _showGroupSecurityInformationalDialog(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.info_outline),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.bottomCenter,
                          iconSize: 20.sp,
                          constraints: BoxConstraints(),
                          style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _users.isEmpty
                        ? SizedBox()
                        : Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "Valid",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        "Username",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    Expanded(
                                      flex: 6,
                                      child: Text(
                                        "Permissions",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    Expanded(flex: 3, child: SizedBox()),
                                  ],
                                ),
                              ),
                            ),

                            Container(
                              constraints: BoxConstraints(
                                minHeight: 20.h,
                                maxHeight: 150.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,

                                children:
                                    _users
                                        .map(
                                          (user) => GroupMemberListTile(
                                            groupMember: user,
                                            deleteTileCallBack:
                                                _deleteGroupMember,
                                            modifySecurityLevelCallBack:
                                                _modifyGroupMemberSecurityLevel,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ],
                        ),

                    _users.isEmpty ? SizedBox() : SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 17,
                          child: Container(
                            height: 42.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _userNameController,

                              decoration: InputDecoration(
                                labelText: "Add member by username",
                                labelStyle: TextStyle(fontSize: 18),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,

                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: IconButton(
                            padding: EdgeInsets.zero,

                            onPressed: () {
                              if (_userNameController.text.isNotEmpty) {
                                _addNameToGroupMembers(
                                  _userNameController.text,
                                );
                              }
                            },
                            icon: Icon(Icons.add, color: Colors.white),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 42.h),

                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                side: BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (_isCreatingGroup) return;
                        if (!_canSubmit) return;
                        setState(() {
                          _isCreatingGroup = true;
                        });

                        late final bool? response;
                        if (widget.groupToEdit != null) {
                          response = await _updateGroup();
                        } else {
                          response = await _createGroup();
                        }
                        setState(() {
                          _isCreatingGroup = false;
                        });

                        if (response == true && context.mounted) {
                          context.pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canSubmit ? Colors.green : Colors.grey,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        maximumSize: Size(double.infinity, 50.h),
                        minimumSize: Size(double.infinity, 50.h),
                        shadowColor: Colors.black,
                      ),
                      child:
                          _isCreatingGroup
                              ? CircularProgressIndicator()
                              : Text(
                                _labelText,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _checkIfSubmitPossible() {
    if (_groupNameController.text.isEmpty) {
      setState(() {
        _canSubmit = false;
      });
    } else if (_groupNameController.text.length > 20) {
      setState(() {
        _canSubmit = false;
      });
    } else {
      setState(() {
        _canSubmit = true;
      });
    }
  }

  void _addNameToGroupMembers(String name) {
    setState(() {
      _users.add(GroupMember(username: name, permissionLevel: 2));
      _userNameController.clear();
    });
  }

  void _deleteGroupMember(GroupMember groupMember) {
    setState(() {
      _users.remove(groupMember);
    });
  }

  void _modifyGroupMemberSecurityLevel(
    GroupMember groupMember,
    int newSecurityLevel,
  ) {
    setState(() {
      groupMember.permissionLevel = newSecurityLevel;
    });
  }

  void _showGroupSecurityInformationalDialog() {
    showDialog(
      context: context,
      builder: (context) => GroupSecurityInformationalDialog(),
    );
  }

  Future<bool?> _updateGroup() async {
    if (_groupNameController.text.isEmpty) {
      showSnackbar(context, "Group name cannot be empty");
      return false;
    }

    if (_groupNameController.text.length > 20) {
      showSnackbar(context, "Group name cannot be longer than 20 characters");
      return false;
    }

    final group = Group(
      id: widget.groupToEdit!.id,
      createdAt: widget.groupToEdit!.createdAt,
      name: _groupNameController.text,
      gradeVisible: _showRatings,
      useRating: _isUsingRating,
      isPersonalGroup: false,
      userId: SupabaseHelper.users.getAuthId()!,
      groupMembers: _users,
      recipes: [],
    );

    final response = await SupabaseHelper.groups.updateGroup(group);

    if (response.success && mounted) {
      final failedMembers = response.failedToAddMembers;

      if (failedMembers != null) {
        for (var failedMember in failedMembers) {
          showSnackbar(context, "Failed to update ${failedMember.username}");
        }
      }

      showSuccessSnackbar(
        context,
        "Group '${_groupNameController.text}' Updated!",
      );

      if (response.failedToAddMembers != null) {
        final failedMembers = response.failedToAddMembers!;
        if (failedMembers.isNotEmpty) {
          for (var failedMember in failedMembers) {
            showSnackbar(context, "Failed to add ${failedMember.username}");
          }
        }
      }
      return true;
    } else {
      if (mounted && response.localError != null) {
        showSnackbar(
          context,
          response.errorMessage ?? "Failed to update group",
        );
      }
      return false;
    }
  }

  Future<bool?> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      showSnackbar(context, "Group name cannot be empty");
      return false;
    }

    if (_groupNameController.text.length > 20) {
      showSnackbar(context, "Group name cannot be longer than 20 characters");
      return false;
    }

    final group = Group(
      id: "NA",
      createdAt: "NA",
      name: _groupNameController.text,
      gradeVisible: _showRatings,
      useRating: _isUsingRating,
      isPersonalGroup: false,
      userId: SupabaseHelper.users.getAuthId()!,
      groupMembers: _users,
      recipes: [],
    );

    final ownerUsername = await SupabaseHelper.users.getUsername();

    if (ownerUsername == null) {
      if (mounted) {
        showSnackbar(context, "Failed to create group, try again later");
      }

      return false;
    }

    group.groupMembers.add(
      GroupMember(username: ownerUsername, permissionLevel: 3),
    );

    group.filterDuplicateMembers();

    final response = await SupabaseHelper.groups.createGroup(group);

    if (response.success && mounted) {
      final failedMembers = response.failedToAddMembers;

      if (failedMembers != null) {
        for (var failedMember in failedMembers) {
          showSnackbar(context, "Failed to add ${failedMember.username}");
        }
      }

      showSuccessSnackbar(
        context,
        "Group '${_groupNameController.text}' created!",
      );

      if (response.failedToAddMembers != null) {
        final failedMembers = response.failedToAddMembers!;
        if (failedMembers.isNotEmpty) {
          for (var failedMember in failedMembers) {
            showSnackbar(context, "Failed to add ${failedMember.username}");
          }
        }
      }
      return true;
    } else {
      if (mounted && response.localError != null) {
        showSnackbar(
          context,
          response.errorMessage ?? "Failed to create group",
        );
      }
      return false;
    }
  }

  Future<bool?> _deleteGroup() async {
    final deleteConfirmation = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteGroupConfirmationDialog(),
    );

    if (deleteConfirmation != true) {
      return false;
    }

    final response = await SupabaseHelper.groups.deleteGroup(
      widget.groupToEdit!.id,
    );

    if (response && mounted) {
      showSuccessSnackbar(
        context,
        "Group '${widget.groupToEdit!.name}' deleted!",
      );
      return true;
    } else {
      if (mounted) {
        showErrorSnackbar(context, "Failed to delete group");
      }
      return false;
    }
  }

  Future<bool?> _leaveGroup() async {
    // Check if user is owner of the group, if so, ask them to delete the group instead
    final currentUserId = SupabaseHelper.users.getAuthId();
    if (currentUserId == null) {
      if (mounted) {
        showSnackbar(context, "Failed to leave group, try again later");
      }
      return false;
    }
    if (currentUserId == widget.groupToEdit!.userId) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "You are the owner of this group. Please delete the group instead.",
        );
      }
      return false;
    }

    // Confirm leaving the group
    final leaveConfirmation = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Leave Group"),
            content: Text(
              "Are you sure you want to leave '${widget.groupToEdit!.name}'?",
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: Text("Cancel", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Leave", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (leaveConfirmation != true) {
      return false;
    }

    final response = await SupabaseHelper.groups.leaveGroup(
      widget.groupToEdit!.id,
    );

    if (response == true && mounted) {
      showSuccessSnackbar(
        context,
        "You have left '${widget.groupToEdit!.name}'!",
      );
      return true;
    } else {
      if (mounted) {
        showSnackbar(context, "Failed to leave group");
      }
      return false;
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
}
