<%@ page import="jetbrains.buildServer.notification.WatchType" %>
<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<jsp:useBean id="notificationRulesForm" type="jetbrains.buildServer.controllers.profile.notifications.NotificationRulesForm" scope="request"/>
<jsp:useBean id="ruleBean" type="jetbrains.buildServer.controllers.profile.notifications.NotificationRulesForm.EditableNotificationRule" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="buildTypeId" type="java.lang.String" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="constants" class="jetbrains.buildServer.serverSide.impl.NotificationRulesConstants" scope="request"/>
<c:set value="<%=WatchType.SPECIFIC_PROJECT_BUILD_TYPES.name()%>" var="SPECIFIC_PROJECT_BUILD_TYPES"/>
<c:set value="<%=WatchType.SYSTEM_WIDE.name()%>" var="SYSTEM_WIDE"/>

<script type="text/javascript">
  $j(function () {
    BS.NotificationRuleForm.initPage('${SPECIFIC_PROJECT_BUILD_TYPES}', '${SYSTEM_WIDE}');
  });
</script>


<tr>
  <th>
    Branch filter:
  </th>
  <td>
    <c:set var="defaultBranchFilter" value="${ruleBean.userChangesFilter ? '+:*' : ruleBean.defaultBranchFilters[SPECIFIC_PROJECT_BUILD_TYPES]}"/>

    <div class="tc-icon_before icon16 tc-icon_branch branchFilter" style="margin-left: 0px;">
      <bs:help file="Branch+Filter"/>
      <props:multilineProperty name="${constants.branchFilter}" linkTitle="Edit Branch Filter" cols="35" rows="3" placeholder="${defaultBranchFilter}"/>
      <span class="error" style="margin-left: 0" id="buildTypeBranchFilterError"></span>
      <script type="text/javascript">
        BS.BranchesPopup.attachBuildTypesHandler(function () {
          return ['${buildTypeId}'];
        }, '${constants.branchFilter}', 'branchFilter', 'ALL_BRANCHES');
      </script>
    </div>
  </td>
</tr>

<tr>
  <th>Events:</th>
  <td>
    <table class="eventsTable" id="non-system-events" style="margin-left: -8px;">
      <tr>
        <td class="buildFailed">
          <props:checkboxProperty name="${constants.buildFinishedFailure}" onclick="if (!this.checked) BS.BuildTypeNotificationRuleForm.unselectFailureEvents();"/>
          <label for="${constants.buildFinishedFailure}">Build fails</label>
        </td>
      </tr>
      <c:if test="${notificationRulesForm.BFNFEnabled}">
        <tr>
          <td class="eventOption">
            <props:checkboxProperty name="${constants.buildFinishedNewFailure}" onclick="BS.BuildTypeNotificationRuleForm.selectEvent('${constants.buildFinishedFailure}')"/>
            <label for="${constants.buildFinishedNewFailure}">Keep notifying until build is complete (even without my changes)</label>
          </td>
        </tr>
      </c:if>
      <tr>
        <td class="eventOption">
          <props:checkboxProperty name="${constants.firstFailureAfterSuccess}" onclick="BS.BuildTypeNotificationRuleForm.selectEvent('${constants.buildFinishedFailure}')"/>
          <label for="${constants.firstFailureAfterSuccess}">Only notify on the first failed build after successful</label>
        </td>
      </tr>
      <tr>
        <td class="eventOption">
          <props:checkboxProperty name="${constants.newBuildProblemOccurred}" onclick="BS.BuildTypeNotificationRuleForm.selectEvent('${constants.buildFinishedFailure}')"/>
          <label for="${constants.newBuildProblemOccurred}">Only notify on new build problem or new failed test</label>
        </td>
      </tr>
      <tr>
        <td>
          <props:checkboxProperty name="${constants.buildFinishedSuccess}" onclick="if (!this.checked) BS.BuildTypeNotificationRuleForm.unselectSuccessEvents();"/>
          <label for="${constants.buildFinishedSuccess}">Build is successful</label>
        </td>
      </tr>
      <tr>
        <td class="eventOption">
          <props:checkboxProperty name="${constants.firstSuccessAfterFailure}" onclick="BS.BuildTypeNotificationRuleForm.selectEvent('${constants.buildFinishedSuccess}')"/>
          <label for="${constants.firstSuccessAfterFailure}">Only notify on the first successful build after failed</label>
        </td>
      </tr>
      <tr>
        <td class="startOfGroup">
          <props:checkboxProperty name="${constants.buildFailing}"/>
          <label for="${constants.buildFailing}">The first build error occurs</label>
        </td>
      </tr>
      <tr>
        <td>
          <props:checkboxProperty name="${constants.buildStarted}"/>
          <label for="${constants.buildStarted}">Build starts</label>
        </td>
      </tr>
      <tr>
        <td>
          <props:checkboxProperty name="${constants.buildFailedToStart}"/>
          <label for="${constants.buildFailedToStart}">Build fails to start</label>
        </td>
      </tr>
      <tr>
        <td>
          <props:checkboxProperty name="${constants.buildProbablyHanging}"/>
          <label for="${constants.buildProbablyHanging}">Build is probably hanging</label>
        </td>
      </tr>
      <tr>
        <td>
          <props:checkboxProperty name="${constants.queuedBuildRequiresApproval}"/>
          <label for="${constants.queuedBuildRequiresApproval}">Build requires my approval</label>
        </td>
      </tr>
    </table>
  </td>
</tr>

<input type="hidden" name="branchFilter" value=""/>
<input type="hidden" name="userChangesFilter" value=""/>
<input type="hidden" name="notificatorType" value="${notificationRulesForm.notificatorType}"/>
<input type="hidden" name="holderId" value="${notificationRulesForm.editeeId}"/>
<input type="hidden" name="submitRule" value="save"/>

<bs:executeOnce id="buildTypeNotificationRuleForm">
  <script>
    BS.BuildTypeNotificationRuleForm = {
      selectEvent: function (event) {
        $j("#" + event).prop("checked", true);
      },

      unselectFailureEvents: function () {
        ["${constants.buildFinishedNewFailure}", "${constants.firstFailureAfterSuccess}", "${constants.newBuildProblemOccurred}"].forEach(function (event) {
          $j("#" + event).prop("checked", false);
        });
      },

      unselectSuccessEvents: function () {
        ["${constants.firstSuccessAfterFailure}"].forEach(function (event) {
          $j("#" + event).prop("checked", false);
        });
      }
    };
  </script>
</bs:executeOnce>
