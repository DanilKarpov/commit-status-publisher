<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>

<%@ page import="jetbrains.buildServer.serverSide.auth.Permission" %>
<jsp:useBean id="buildTypeId" type="java.lang.String" scope="request"/>
<jsP:useBean id="buildType" type="jetbrains.buildServer.serverSide.BuildTypeSettings" scope="request"/>
<jsp:useBean id="user" type="jetbrains.buildServer.users.SUser" scope="request"/>
<jsp:useBean id="availableNotifiers" type="java.util.Collection<jetbrains.buildServer.notification.BuildTypeNotifierDescriptor>" scope="request"/>
<jsp:useBean id="featureId" type="java.lang.String" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>

<c:url var="userLevelNotificationsUrl" value="/profile.html?item=userNotifications"/>

<tbody>
<td colspan="2">
  <em>This build feature allows sending notifications about different build events. <bs:help file="Notifications"/>
    <br/>
    For personal notifications, consider configuring <a href="${userLevelNotificationsUrl}">user notification rules</a> instead.
  </em>
</td>

<tr>
  <th>
    Notifier:<l:star/>
  </th>
  <td>
    <props:selectProperty name="notifier" id="notifierSelector" onchange="BS.EditBuildTypeNotificationRules.update()">
      <props:option value="">-- Choose notifier --</props:option>
      <c:forEach items="${availableNotifiers}" var="notifier">
        <props:option value="${util:forJS(notifier.type, true, false)}">
          <bs:out value="${notifier.displayName}"/>
        </props:option>
      </c:forEach>
    </props:selectProperty>

    <forms:saving id="loadingNotificationRule"/>

    <span class="error" id="error_notifier"></span>
  </td>
</tr>

</tbody>

<tbody id="notificationRulesContainer">
</tbody>

<script>
  BS.EditBuildTypeNotificationRules = {
    update: function () {
      var loader = $j("#loadingNotificationRule");

      var selectedNotifier = $j("#notifierSelector option:selected").val();
      var rulesContainer = $j("#notificationRulesContainer");
      if (!selectedNotifier) {
        rulesContainer.empty();
        return;
      }

      loader.show();

      BS.ajaxUpdater('notificationRulesContainer', '<c:url value="/admin/editBuildTypeNotifierSettings.html"/>', {
        parameters: {
          notificatorType: selectedNotifier,
          filterType: "buildType",
          filter: "${util:forJS(buildTypeId, true, false)}",
          id: "${util:forJS(buildTypeId, true, false)}",
          newRule: true,
          featureId: "${util:forJS(featureId, true, false)}"
        },
        method: "get",
        evalScripts: true,
        onComplete: function () {
          loader.hide();

          <c:if test="${
            !user.isPermissionGrantedForProject(buildType.project.projectId, Permission.EDIT_PROJECT) or buildType.project.readOnly
          }">
          BS.BuildFeatureDialog.setReadOnly();
          </c:if>
        }
      });
    }
  };

  BS.EditBuildTypeNotificationRules.update();
</script>
