<%@ page import="jetbrains.buildServer.serverSide.NodeResponsibility" %>
<%@ page import="jetbrains.buildServer.controllers.interceptors.proxy.UsersLoadBalancer" %>
<%@include file="/include-internal.jsp" %>

<jsp:useBean id="repositorySettings" scope="request" type="jetbrains.buildServer.controllers.admin.RepositoryConfigurationBean"/>

<c:url value="/admin/centralRepositoryConfiguration.html" var="url"/>
<div id="settingsContainer">
<forms:multipartForm id="centralRepositoryConfiguration" action="${url}" onsubmit="return BS.ConfigsInGit.sendRequest()">
    <div>
      <table class="runnerFormTable" id="configsInGitTable">
        <tr>
          <th colspan="2" style="padding-top: 8px; padding-bottom: 12px">
            <forms:checkbox name="isEnabled" checked="${repositorySettings.enabled}" onclick="BS.ConfigsInGit.enabledStateChanged(this.checked)"/>
            <label for="isEnabled">Commit changes in configuration files to the configs repository</label>
            <bs:help file="TeamCity+Data+Directory" anchor="centralRepository"/>
          </th>
        </tr>
        <tr>
          <th style="border-top: none"><label for="url">Repository URL:<l:star/></label></th>
          <td style="border-top: none">
            <forms:textField name="url" value="${repositorySettings.url}" style="width: 30em" className="js-disable"/>
          </td>
        </tr>

        <tr>
          <th><label for="url">Branch:<l:star/></label></th>
          <td>
            <forms:textField name="branch" value="${repositorySettings.branch}" style="width: 30em" className="js-disable"/>
          </td>
        </tr>

        <tr>
          <th><label for="url">Private key:<l:star/></label></th>
          <td id="js-fileToUpload">
            <forms:file name="fileToUpload"/>
            <c:if test="${keyUploaded}">
              <bs:smallNote>Private key is uploaded</bs:smallNote>
            </c:if>
          </td>
        </tr>

      </table>
    </div>
  <div>
    <forms:attentionComment>Warning: Configuration files contain scrambled passwords, database parameters,
      and other sensitive data that must be stored securely.
      Therefore, use a local Git repository on the same machine as your TeamCity server,
      or an external Git repository accessible only to your TeamCity server administrators.</forms:attentionComment>
  </div>
    <div class="saveButtonsBlock" id="saveButtons">
      <forms:submit label="Save"/>
      <forms:saving/>
    </div>
</forms:multipartForm>
</div>

<c:if test="${repositorySettings.enabled}">
  <div id="configsCurrentState">
    <c:choose>
      <c:when test="${stateExists}">
        <div>
          <h3>Current status:</h3>
          <span>[<bs:date value="${timestamp}" pattern="${dateFormat}"/>]: </span><span <c:if test="${currentState.error}">class="error" style="margin: 0px"</c:if>><c:out value="${currentState.messageForUI}"/></span>
        </div>
      </c:when>
      <c:otherwise>
        <div>Current status is unknown</div>
      </c:otherwise>
    </c:choose>
  </div>
</c:if>

<script>
  BS.ConfigsInGit = {

    enabledStateChanged: function(enabled) {
      $j('#configsInGitTable .js-disable').attr('disabled', !enabled);
      $j('#configsInGitTable #js-fileToUpload input').attr('disabled', !enabled);
    },

    sendRequest: function () {
      var form = $j('#centralRepositoryConfiguration');
      var actionUrl = form.attr('action');
      $j.ajax({
        type: "POST",
        url: actionUrl,
        enctype: 'multipart/form-data',
        contentType: false,
        processData: false,
        data: new FormData(form[0]),
        success: function(data) {
          BS.reload(true)
        }
      });
      return false;
    }
  };

  $j(document).ready(function() {
    BS.ConfigsInGit.enabledStateChanged($j('#configsInGitTable #isEnabled').prop('checked'))
  });
</script>