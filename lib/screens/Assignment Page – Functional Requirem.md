ag Assignment Page – Functional Requirements
1. Tag Lists Layout
Left List Box:
Displays all available tags (excluding those already assigned to the current user).
Supports multi-selection.
Right List Box:
Displays all tags currently assigned to the user.
Supports multi-selection.
2. Assign/Unassign Actions
Assign:
User selects one or more tags in the left box and clicks "Assign".
The selected tags are assigned to the user.
The right box updates to include the newly assigned tags.
The left box removes the assigned tags from its list.
Unassign:
User selects one or more tags in the right box and clicks "Unassign".
The selected tags are unassigned from the user.
The right box removes the unassigned tags.
The left box updates to include the unassigned tags.
3. Tag Filtering & Grouping
No Duplicates:
Tags already assigned (in the right box) are not shown in the left box.
Hierarchical Grouping:
Tags with labels like xx1::xx2::xx3 are displayed in a collapsible/expandable tree structure, similar to Anki.
Users can group/ungroup tags visually by their hierarchy.
4. Tag Deletion
Delete Button:
For tags in the right box that are owned by the current user, show a "Delete" button.
Clicking "Delete" removes the tag from both the user's assigned tags and the global tag list (if applicable).
Only user-owned tags can be deleted by the user.
5. UI/UX
Multi-Select:
Both list boxes support multi-selection (e.g., with checkboxes or shift/ctrl+click).
Immediate Feedback:
After assign/unassign/delete actions, both lists update immediately to reflect the changes.
Clear Grouping:
Grouped tags are visually distinct and can be expanded/collapsed.
6. Data Sources
All Tags:
Fetched from the backend (excluding user-assigned tags).
User Tags:
Fetched from the backend for the current user.