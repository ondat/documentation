---
title: "User Management"
linkTitle: User Management
---

An Ondat cluster admin can create users and restrict their access rights to
Ondat [namespaces](/docs/operations/namespaces) using
[policies](/docs/operations/policies).

>💡 Users are created with access to the default namespace. This access is
>only revoked when a policy is created for the user or their group. 

## Managing users

Users can be created and deleted by navigating to the "Users" section of the GUI.

Alternatively users can also be managed using the CLI.

To create a user with the CLI, run:

```bash
$ storageos user create jim
```

The above command will create a user named jim. The command will also prompt
you to enter a password for the newly created user.

