import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Pages.js" as Pages
import qs.Commons
import qs.Portals
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var initial: pluginApi?.initialSettings || ({})
  readonly property bool sharedContent: pluginApi?.scopeKind === "plugin"
  readonly property var showCompletedField: pluginApi?.field("showCompleted")
  readonly property var showBackgroundField: pluginApi?.field("showBackground")
  readonly property var useCustomColorsField: pluginApi?.field("useCustomColors")
  readonly property var priorityColorsField: pluginApi?.field("priorityColors")
  readonly property var exportPathField: pluginApi?.field("exportPath")
  readonly property var exportFormatField: pluginApi?.field("exportFormat")
  readonly property var exportEmptySectionsField: pluginApi?.field("exportEmptySections")
  readonly property var editPages: pluginApi?.pluginSettings.pages || []
  readonly property var editTodos: pluginApi?.pluginSettings.todos || []
  readonly property int editCurrentPage: pluginApi?.pluginSettings.current_page_id ?? 0
  property var pendingNames: Pages.names(editPages)
  property bool namesPending: false
  property string newPageName: ""
  readonly property bool settingsDirty: namesPending || newPageName.length > 0

  function setPendingName(id, value) {
    if (!sharedContent)
      return;
    var next = Object.assign({}, pendingNames);
    next[String(id)] = value;
    pendingNames = next;
    namesPending = true;
  }
  function renamePage(id, name) {
    name = name.trim();
    var index = editPages.findIndex(page => page.id === id);
    if (!sharedContent || !name || !isPageNameUnique(name, index))
      return false;
    if (!pluginApi.contentField("pages").set(Pages.rename(editPages, id, name)))
      return false;
    setPendingName(id, name);
    return true;
  }

  readonly property bool valueShowCompleted: showCompletedField?.value ?? false
  readonly property bool valueShowBackground: showBackgroundField?.value ?? false

  // Priority color properties
  readonly property bool valueUseCustomColors: useCustomColorsField?.value ?? false
  readonly property color valueHighPriorityColor: priorityColorsField?.value?.high || AtmoColor.mError
  readonly property color valueMediumPriorityColor: priorityColorsField?.value?.medium || AtmoColor.mPrimary
  readonly property color valueLowPriorityColor: priorityColorsField?.value?.low || AtmoColor.mOnSurfaceVariant
  function setPriorityColor(key, color) {
    var next = Object.assign({}, priorityColorsField.value);
    next[key] = color.toString();
    return priorityColorsField.set(next);
  }

  // Export path property
  readonly property string valueExportPath: exportPathField?.value ?? ""
  readonly property string valueExportFormat: exportFormatField?.value ?? ""
  readonly property bool valueExportEmptySections: exportEmptySectionsField?.value ?? false

  // Reference to Main.qml instance for centralized data management
  readonly property var mainInstance: pluginApi?.mainInstance

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("Todo", "Settings UI loaded");
  }

  NPluginSettingsField {
    field: root.showCompletedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show_completed.label")
      description: pluginApi?.tr("settings.show_completed.description")
      checked: root.valueShowCompleted
      onToggled: function (checked) {
        root.showCompletedField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showBackgroundField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.background_color.label")
      description: pluginApi?.tr("settings.background_color.description")
      checked: root.valueShowBackground
      onToggled: function (checked) {
        root.showBackgroundField.set(checked);
      }
    }
  }

  // Toggle for custom priority colors
  NPluginSettingsField {
    field: root.useCustomColorsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.custom_priority_colors.label")
      description: pluginApi?.tr("settings.custom_priority_colors.description")
      checked: root.valueUseCustomColors
      onToggled: function (checked) {
        root.useCustomColorsField.set(checked);
      }
    }
  }

  // Section for priority color settings (only visible when custom colors are enabled)
  NPluginSettingsField {
    field: root.priorityColorsField
    Layout.fillWidth: true
    spacing: Style.marginS
    visible: root.valueUseCustomColors

    NText {
      text: pluginApi?.tr("settings.priority_colors.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    GridLayout {
      columns: 2
      rowSpacing: Style.marginS
      columnSpacing: Style.marginM
      Layout.fillWidth: true

      // High priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.high_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerHigh
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueHighPriorityColor
        onColorSelected: function (color) {
          root.setPriorityColor("high", color);
        }
      }

      // Medium priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.medium_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerMedium
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueMediumPriorityColor
        onColorSelected: function (color) {
          root.setPriorityColor("medium", color);
        }
      }

      // Low priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.low_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerLow
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueLowPriorityColor
        onColorSelected: function (color) {
          root.setPriorityColor("low", color);
        }
      }
    }
  }

  // Export path setting
  NPluginSettingsField {
    field: root.exportPathField
    NTextInputButton {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.export_path.label")
      description: pluginApi.tr("settings.export_path.description")
      placeholderText: pluginApi.tr("settings.export_path.placeholder")
      text: root.valueExportPath
      buttonIcon: "folder-open"
      buttonTooltip: pluginApi.tr("settings.export_path.select_folder")
      onInputEditCommitted: root.exportPathField.set(text)
      onButtonClicked: folderPicker.openFilePicker()
    }
  }

  // Export format setting
  NPluginSettingsField {
    field: root.exportFormatField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.export_format.label")
      description: pluginApi.tr("settings.export_format.description")
      model: [
        {
          key: "markdown",
          name: pluginApi.tr("settings.export_format.markdown")
        },
        {
          key: "json",
          name: pluginApi.tr("settings.export_format.json")
        }
      ]
      currentKey: root.valueExportFormat
      onSelected: function (key) {
        root.exportFormatField.set(key);
      }
    }
  }

  // Export empty sections setting
  NPluginSettingsField {
    field: root.exportEmptySectionsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.export_empty_sections.label")
      description: pluginApi.tr("settings.export_empty_sections.description")
      checked: root.valueExportEmptySections
      onToggled: function (checked) {
        root.exportEmptySectionsField.set(checked);
      }
    }
  }

  // Folder picker for selecting export path
  PortalFilePicker {
    id: folderPicker
    selectionMode: "folders"
    title: pluginApi.tr("settings.export_path.label")
    initialPath: root.valueExportPath
    onAccepted: function (paths) {
      if (paths.length > 0) {
        root.exportPathField.set(paths[0]);
      }
    }
  }

  // Section for managing pages
  NText {
    visible: !root.sharedContent
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    text: pluginApi.tr("settings.pages.shared_scope")
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    enabled: root.sharedContent

    NText {
      text: pluginApi?.tr("settings.pages.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    // Input for adding new pages
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInput {
        id: newPageInput
        text: root.newPageName
        onTextEdited: root.newPageName = text
        placeholderText: pluginApi?.tr("settings.pages.placeholder")
        Layout.fillWidth: true
        Keys.onReturnPressed: addPage()
      }

      NButton {
        text: pluginApi?.tr("settings.pages.add_button")
        onClicked: addPage()
      }
    }

    // List of existing pages with proper scrolling
    Item {
      Layout.fillWidth: true
      height: 200

      Flickable {
        id: pagesListView
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        ScrollBar.vertical: ScrollBar {
          parent: pagesListView
          anchors.top: pagesListView.top
          anchors.right: pagesListView.right
          anchors.bottom: pagesListView.bottom
          policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: root.editPages

            delegate: Item {
              width: parent.width
              height: Style.baseWidgetSize

              property bool editing: false
              property string originalName: modelData.name || ""

              // Function to save the renamed page
              function saveRename() {
                var newName = renameInput.text.trim();
                if (newName === "") {
                  cancelRename();
                  return;
                }

                if (newName === originalName) {
                  editing = false;
                  return;
                }

                if (!isPageNameUnique(newName, index)) {
                  ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
                  return;
                }

                // Use mainInstance to rename page
                root.renamePage(modelData.id, newName);

                originalName = newName;
                editing = false;
              }

              // Function to cancel renaming
              function cancelRename() {
                if (renameInput) {
                  root.setPendingName(modelData.id, originalName);
                }
                editing = false;
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginS

                // Container for the normal view (when not editing)
                Item {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  visible: !editing

                  RowLayout {
                    anchors.fill: parent
                    spacing: Style.marginS

                    NText {
                      text: modelData.name
                      Layout.fillWidth: true
                      verticalAlignment: Text.AlignVCenter
                    }

                    AtmoIconButton {
                      icon: "pencil"
                      tooltipText: pluginApi?.tr("settings.pages.rename_button_tooltip")
                      onClicked: {
                        // Switch to editing mode and capture the current name
                        originalName = modelData.name;
                        editing = true;
                      }
                    }

                    AtmoIconButton {
                      icon: "trash"
                      tooltipText: pluginApi?.tr("settings.pages.delete_button_tooltip")
                      colorFg: AtmoColor.mError
                      enabled: root.editPages.length > 1 && modelData.id !== 0
                      onClicked: {
                        if (root.editPages.length <= 1) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
                          return;
                        }

                        if (modelData.id === 0) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
                          return;
                        }

                        // Show confirmation dialog before deleting
                        root.showDeleteConfirmation(index, modelData.name);
                      }
                    }
                  }
                }

                // Editing UI - only visible when in editing mode
                RowLayout {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  spacing: Style.marginS
                  visible: editing

                  NTextInput {
                    id: renameInput
                    text: root.pendingNames[String(modelData.id)] || ""
                    onTextEdited: root.setPendingName(modelData.id, text)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 150
                    focus: editing

                    Keys.onReturnPressed: saveRename()
                    Keys.onEscapePressed: cancelRename()

                    onVisibleChanged: {
                      if (visible && editing) {
                        forceActiveFocus();
                      }
                    }
                  }

                  NButton {
                    text: "✓"
                    fontSize: Style.fontSizeS
                    backgroundColor: AtmoColor.mPrimary
                    textColor: AtmoColor.mOnPrimary
                    onClicked: saveRename()
                  }

                  NButton {
                    text: "✕"
                    fontSize: Style.fontSizeS
                    backgroundColor: AtmoColor.mError
                    textColor: AtmoColor.mOnError
                    onClicked: cancelRename()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function isPageNameUnique(name, excludeIndex) {
    var pages = editPages;
    var lowerName = name.toLowerCase().trim();
    for (var i = 0; i < pages.length; i++) {
      if (i !== excludeIndex && pages[i].name.toLowerCase().trim() === lowerName) {
        return false;
      }
    }
    return true;
  }

  function addPage() {
    if (!sharedContent)
      return;
    var name = newPageName.trim();

    if (name === "") {
      ToastService.showError(pluginApi?.tr("settings.pages.empty_name"));
      return;
    }

    if (!isPageNameUnique(name, -1)) {
      ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
      return;
    }

    // Use mainInstance to create page
    if (!pluginApi.contentField("pages").set(Pages.create(editPages, name)))
      return;
    pendingNames = Pages.names(editPages, pendingNames);

    newPageName = "";
    newPageInput.forceActiveFocus();
  }

  // Confirmation dialog for page deletion
  Popup {
    id: confirmDialog
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 300
    height: 150

    background: Rectangle {
      color: AtmoColor.mSurface
      border.color: AtmoColor.mOutline
      border.width: 1
      radius: Style.radiusL
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        id: confirmText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Are you sure you want to delete this page?"
        verticalAlignment: Text.AlignVCenter
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Style.marginS

        NButton {
          text: "Cancel"
          onClicked: confirmDialog.close()
        }

        NButton {
          text: "Delete"
          textColor: AtmoColor.mOnError
          backgroundColor: AtmoColor.mError
          onClicked: {
            performPageDeletion(confirmDialog.pageIndex);
            confirmDialog.close();
          }
        }
      }
    }

    // Property to store the index of the page to delete
    property int pageIndex: -1
  }

  // Function to show the confirmation dialog
  function showDeleteConfirmation(pageIdx, pageName) {
    confirmDialog.pageIndex = pageIdx;
    var confirmMessage = pluginApi?.tr("settings.pages.confirm_delete_message");
    confirmText.text = confirmMessage.replace("{pageName}", pageName);
    confirmDialog.open();
  }

  // Function to perform the actual page deletion
  function performPageDeletion(pageIdx) {
    if (!sharedContent || pageIdx < 0)
      return;

    var pages = editPages;

    // Prevent deleting default page (id: 0)
    if (pages[pageIdx].id === 0) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
      return;
    }

    if (pages.length <= 1) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
      return;
    }

    var pageToDeleteId = pages[pageIdx].id;

    // Use mainInstance to delete page (handles todos migration and current_page_id update)
    var next = Pages.remove(editPages, editTodos, editCurrentPage, pageToDeleteId);
    pluginApi.contentField("pages").set(next.pages);
    pluginApi.contentField("todos").set(next.todos);
    pluginApi.contentField("current_page_id").set(next.current);
    pendingNames = Pages.names(editPages, pendingNames);
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Todo", "Cannot save settings: pluginApi is null");
      return;
    }

    if (sharedContent && (namesPending || newPageName.length > 0)) {
      if (!pluginApi.contentField("pages").set(Pages.withNames(editPages, pendingNames, newPageName)))
        return false;
      pendingNames = Pages.names(editPages);
      namesPending = false;
      newPageName = "";
    }

    pluginApi.saveSettings();

    return;
  }
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Todo", "Settings saved successfully");
    }
  }
}
