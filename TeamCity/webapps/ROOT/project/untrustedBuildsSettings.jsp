<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@
    taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %><%@
    taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %><%@
    taglib prefix="bs" tagdir="/WEB-INF/tags" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %><%@
    taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<jsp:useBean id="untrustedBuildsBean" type="jetbrains.buildServer.controllers.admin.security.UntrustedBuildsBean" scope="request"/>

<%--@elvariable id="pageUrl" type="java.lang.String"--%>
<%--@elvariable id="currentProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="settingsProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="canEditProject" type="java.lang.Boolean"--%>

<style type="text/css">
  #untrustedSettingsTable th {
    padding-left: 0px;
    text-align: left;
  }
  #untrustedSettingsTable input {
    accent-color: #008EFF;
  }
</style>


<table class="runnerFormTable" id="untrustedSettingsTable">
  <h2 class="noBorder">Untrusted Builds Settings</h2>
  <bs:smallNote>
  This page contains settings related to untrusted builds detection.
    Untrusted builds are builds that include changes authored by external users. Typically, these changes originate from forked repositories and arrive in pull requests.
    <bs:help file="Untrusted+Builds"/>
  </bs:smallNote>

  <div style="margin-top: 16px; margin-bottom: 16px">
    <c:choose>
      <c:when test="${settingsProject.projectId.equals(currentProject.projectId)}">
        <bs:out>Settings are set in the current project</bs:out>
      </c:when>
      <c:otherwise>
        Settings were imported from: <admin:editProjectLink projectId="${settingsProject.externalId}" addToUrl="&tab=untrustedBuilds"><c:out value="${settingsProject.name}"/></admin:editProjectLink>
      </c:otherwise>
    </c:choose>
  </div>

  <tr>
    <th class="noBorder"><label for="defaultActionSelector">Default action:</label></th>
    <td class="noBorder">
      <forms:select id="defaultActionSelector" name="defaultActionSelector" style="width: 10em" disabled="${not canEditProject}" onchange="BS.UntrustedBuildsSettings.onActionChange();">
            <c:forEach items="${untrustedBuildsBean.defaultActionOptions}" var="defaultAction">
              <forms:option value="${defaultAction.first}">
                <c:out value="${defaultAction.second}"/>
              </forms:option>
            </c:forEach>
      </forms:select>
      <span class="smallNote">The default policy that dictates the handling of untrusted builds</span>
    </td>
  </tr>

  <tr>
    <th class="noBorder"><label for="enableLog">Logging:</label></th>
    <td class="noBorder">
      <props:checkboxProperty name="enableLog" id="enableLog" disabled="${not canEditProject}"/>
      <label for="enableLog">${"Log untrusted builds"}</label>
      <span class="smallNote">If this setting is on, the server log keeps records of untrusted builds and related build logs show corresponding warnings</span>
    </td>
  </tr>

  <tr id="approvalRules" style="display: none">
    <th class="noBorder"><label for="rules">Approval rules:<l:star/></label></th>
    <td class="noBorder">
      <props:multilineProperty name="rules" linkTitle="Specify approval rules" className="longField" cols="20" rows="5" expanded="true" disabled="${not canEditProject}"
                               note="Use <code>user:&lt;username&gt;</code> for individuals and <code>group:&lt;group key&gt;:&lt;required count&gt;</code> for groups (group keys are case-sensitive).
                                     Each new line adds to a previous ruleset using the logical \"AND\" operator. To combine users and groups with a shared vote count, use brackets: <code>(users:johndoe,janedoe,groups:ADMINS,DEVS):2</code>" />
      <span class="error" id="error_rules"></span>
    </td>
  </tr>

  <tr id="manualStartIsApprovalSection" style="display: none">
    <th class="noBorder"><label for="manualStartIsApproval">Auto-approval:</label></th>
    <td class="noBorder">
      <props:checkboxProperty name="manualStartIsApproval" disabled="${not canEditProject}"/>
      <label for="manualStartIsApproval">${"Approve manually started builds"}</label>
      <span class="smallNote">If a user listed in "Approval rules" manually triggers an untrusted build, TeamCity automatically adds an approval from this user. The build can then be delayed or processed, depending on whether this single approval is sufficient to run untrusted builds</span>
    </td>
  </tr>

  <tr class="advancedSetting" id="timeoutSection" style="display: none;">
    <th class="noBorder"><label for="timeout">Timeout:</label></th>
    <td class="noBorder">
      <props:textProperty name="timeout" style="width: 10em" disabled="${not canEditProject}" className="mediumField"/>
      <span class="error" id="error_timeout"></span>
      <span class="smallNote">TeamCity automatically cancels untrusted builds that remain in queue longer than the specified value (in minutes). The default value is 360.</span>
    </td>
  </tr>

  <tr id="showAdvancedSection" style="display: none">
    <td class="noBorder">
      <admin:showHideAdvancedOpts containerId="untrustedSettingsTable" optsKey="UntrustedBuildsSettingsPage"/>
    </td>
  </tr>

  <c:if test="${canEditProject}">
    <tr>
      <td class="noBorder">
        <div style="display: flex">
          <forms:submit label="Save settings" onclick="BS.UntrustedBuildsSettings.saveSettings('${currentProject.projectId}')"/>
          <forms:button onclick="BS.UntrustedBuildsSettings.reset('${currentProject.projectId}')">Reset</forms:button>
        </div>
      </td>
    </tr>

    <bs:messages key="untrustedSettingsSaved"/>
  </c:if>
</table>



<script type="text/javascript">
  (function() {
    BS.UntrustedBuildsSettings = {
      actionsUrl: window['base_uri'] + "/admin/untrustedBuildsActions.html",
      onActionChange: function() {
        if (document.getElementById("defaultActionSelector").value === "approve") {
          document.getElementById("approvalRules").show();
          document.getElementById("timeoutSection").show();
          document.getElementById("manualStartIsApprovalSection").show();
          document.getElementById("showAdvancedSection").show();
        } else {
          document.getElementById("approvalRules").hide();
          document.getElementById("timeoutSection").hide();
          document.getElementById("manualStartIsApprovalSection").hide();
          document.getElementById("showAdvancedSection").hide();
        }
      },

      saveSettings: function(projectId) {
        $('error_rules').innerHTML = '';
        $('error_timeout').innerHTML = '';
        var defaultAction = document.getElementById("defaultActionSelector").value;
        var rulesElem = document.getElementById("rules");
        var rules = "";
        if (defaultAction == "approve" && rulesElem) {
          rules = rulesElem.value;
        }
        var params = {
          defaultAction: defaultAction,
          enableLog: document.getElementById("enableLog").checked,
          rules: rules,
          timeout: document.getElementById("timeout").value,
          manualStartIsApproval: document.getElementById("manualStartIsApproval").checked,
          action: "save",
          projectId: projectId
        };
        BS.ajaxRequest(this.actionsUrl, {
          method: "post",
          parameters: params,
          onComplete: this.setErrors
        });
      },

      reset: function (projectId) {
        var params = {
          projectId: projectId,
          action: "reset"
        };
        BS.ajaxRequest(this.actionsUrl, {
          method: "post",
          parameters: params,
          onComplete: this.setErrors
        })
      },

      setErrors: function (response) {
        var errors = BS.XMLResponse.processErrors(response.responseXML, {
          onInvalidApprovalRulesError: function (elem) {
            $('error_rules').innerHTML = BS.Util.escape(elem.firstChild.nodeValue)
          },
          onInvalidTimeoutError: function (elem) {
            $('error_timeout').innerHTML = BS.Util.escape(elem.firstChild.nodeValue);
            $('untrustedSettingsTable')._advancedOptions.showAdvanced(true, false);
          }
        });
        if (!errors) {
          window.location.reload();
        }
      }
    };
  })();

  BS.UntrustedBuildsSettings.onActionChange();
</script>