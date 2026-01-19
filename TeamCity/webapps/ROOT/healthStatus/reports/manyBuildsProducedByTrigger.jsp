<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="triggerError" value="${healthStatusItem.additionalData['triggerError']}"/>
<c:set var="ttlHours" value="${healthStatusItem.additionalData['ttlHours']}"/>
<div>
  A <c:out value="${triggerError.triggerDescription}"/> in the build configuration
  <admin:editBuildTypeLink buildTypeId="${triggerError.buildType.externalId}" step="buildTriggers"><c:out value="${triggerError.buildType.name}"/>
  </admin:editBuildTypeLink> ${triggerError.message}
</div>
<div>
  You can:
  <ul>
    <li><admin:editBuildTypeLink buildTypeId="${triggerError.buildType.externalId}" step="buildTriggers">Review trigger settings</admin:editBuildTypeLink></li>
    <li><a href="#" onclick="BS.triggersErrorsActions.removeTriggeredBuilds('${triggerError.triggerId}','${triggerError.buildType.internalId}')">Remove all of the builds produced by this trigger if they are still queued</a></li>
    <li>Hide this health report (if the trigger settings are correct) with the buttons below</li>
  </ul>
  Note: this health report will be automatically resolved if the problem won't happen again in 24 hours.
</div>
<script type="text/javascript">
  BS.triggersErrorsActions = {
    removeTriggeredBuilds: function(triggerId, buildTypeInternalId) {
      var action = function () {
        BS.ajaxRequest(BS.AdminActions.url, {
            method: "post",
            parameters: "removeErrorActionType=removeTriggeredBuilds&triggerId=" + triggerId + "&buildTypeInternalId=" + buildTypeInternalId,
            onComplete: function () {
              BS.reload();
            }
          }
        );
      };

      BS.confirmDialog.show({
        text: 'Are you sure you want to remove all of the builds produced by the trigger from the build queue?',
        title: "Remove Queued Builds",
        actionButtonText:  "Remove",
        cancelButtonText: 'Cancel',
        action: action
      });
      return false;
    },

    removeTriggerErrors: function(triggerId, buildTypeInternalId) {
      var action = function () {
        BS.ajaxRequest(BS.AdminActions.url, {
            method: "post",
            parameters: "removeErrorActionType=removeErrors&triggerId=" + triggerId + "&buildTypeInternalId=" + buildTypeInternalId,
            onComplete: function () {
              BS.reload();
            }
          }
        );
      };

      BS.confirmDialog.show({
        text: 'Are you sure you want to remove the trigger error?',
        title: "Remove Trigger Error",
        actionButtonText:  "Remove",
        cancelButtonText: 'Cancel',
        action: action
      });
      return false;
    }
  }
</script>