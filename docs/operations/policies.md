---
linkTitle: Policies
---

# Policies

Policies control access to Ondat namespaces. Policies can be
configured at the group or user level so access can be controlled granularly.

Users can belong to one or more groups to control their namespace permissions.
Additionally user specific policies can be created to grant a user access to a
namespace. Users can belong to any number of groups and have any number of
user level policies configured.

>Note: Users are created with access to the default namespace. Policies cannot
be applied to the default namespace.

## Managing Policies

To start creating policies, at least one custom namespace and user are
required. For more information on how to create namespaces, see our
[Namespace guide](/docs/operations/namespaces), and for users see
our [Users CLI reference](/docs/reference/cli/create).

In order to create a policy navigate to "Policies" in the GUI and select
"Create Policy". A policy controls access to a variety of Ondat resources
and is applied to a user, by placing the user in the policies group.

In order to delete a policy, all users must be removed from the policy group
before deletion of the policy can be completed.
