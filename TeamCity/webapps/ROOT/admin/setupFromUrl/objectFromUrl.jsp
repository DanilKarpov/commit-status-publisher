<%@ page import="jetbrains.buildServer.serverSide.crypt.RSACipher" %>
<%@ page import="jetbrains.buildServer.controllers.admin.projects.setupFromUrl.CreateObjectFromUrlController" %>
<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:useBean id="createFromUrlBean" type="jetbrains.buildServer.controllers.admin.projects.setupFromUrl.CreateFromUrlBean" scope="request"/>
<c:set var="propSshKeySupport" value="<%=CreateObjectFromUrlController.SSH_KEY_SUPPORT_TOGGLE%>"/>
<c:set var="sshKeySupportEnabled" value="${intprop:getBooleanOrTrue(propSshKeySupport)}"/>
<c:set var="parentProject" value="${createFromUrlBean.parentProject}"/>
<c:set var="title" value="${createFromUrlBean.objectType == 'PROJECT' ? 'Create Project From URL' : 'Create Build Configuration From URL'}"/>
<c:set var="canEditProject" value="${afn:permissionGrantedForProject(parentProject, 'EDIT_PROJECT') and not parentProject.virtual}"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<%--@elvariable id="embedded" type="java.lang.Boolean"--%>
<%--@elvariable id="readOnly" type="java.lang.Boolean"--%>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>
<c:set var="myCloseAndRefreshAction">
  BS.CreateFromUrlForm.storeUserDataForReload($j('#fileName').val());
</c:set>
<c:set var="formContent">
  <script type="text/javascript">
    BS.CreateFromUrlForm = OO.extend(BS.AbstractPasswordForm, {
      KEY_AUTH: "key",
      PASS_AUTH: "pass",

      formElement: function() {
        return $('createFromUrlForm');
      },

      submit: function() {
        var that = this;
        $('password').enable();
        BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
          parentId: function(elem) {
            $j('#error_parentId').text(elem.firstChild.nodeValue);
            that.highlightErrorField($("parentId"));
          },

          url: function(elem) {
            $j('#error_url').text(elem.firstChild.nodeValue);
            that.highlightErrorField($("url"));
          },

          teamcitySshKey: function (elem) {
            $j('#error_teamcitySshKey').text(elem.firstChild.nodeValue);
            that.highlightErrorField($("teamcitySshKey"));
          },

          onSuccessfulSave : function(responseXML) {
            BS.XMLResponse.processRedirect(responseXML);
          }
        }));

        return false;
      },

      selectAuthType: function (authType) {
        $j('#authType_select').val(authType).change();
      },

      onAuthTypeChange: function (resetHidden) {
        const authType = $j('#authType_select').val();
        const isPassphraseHidden = $j('.sshKeyPassphrase').is(':hidden');
        BS.Util.toggleDependentElements(authType, 'authTypeOption', resetHidden, undefined);
        if (isPassphraseHidden) {
          $j('.sshKeyPassphrase').hide();
        }
      },

      setAuthTypeSelectAvailability: function (optionValue, isAvaliable) {
        $j('#authType_select option[value="' + optionValue + '"]').attr("disabled", !isAvaliable);
      },

      _predictAuthType: function (url) {
        const lowerUrl = url.toLowerCase().trim();
        if (lowerUrl.indexOf('https://') == 0 || lowerUrl.indexOf('http://') == 0) {
          return this.PASS_AUTH;
        } else if (lowerUrl.startsWith("ssh://") || lowerUrl.startsWith("git@")) {
          return this.KEY_AUTH;
        }
        return undefined;
      },

      _switchToAuthType: function (authType) {
        const $selector = $j('#authType_select');
        const currentVal = $selector.val();
        if (currentVal !== authType) {
          $selector.val(authType).change();
          this.selectAuthType(authType);
        }
      },

      onUrlChange: function (newVal) {
        const authType = this._predictAuthType(newVal);
        switch (authType) {
          case this.KEY_AUTH:
            this._switchToAuthType("sshKeyAuthType");
            break;
          case this.PASS_AUTH:
            this._switchToAuthType("passwordAuthType");
            break;
          default:
            this._switchToAuthType("passwordAuthType");
            break;
        }
      },

      onParentProjectChange: function (newVal) {
        $j('#sshKeyDialogProjectId').val(newVal);
      },

      storeUserDataForReload: function (newSshKeyName) {
        const parentProjectId = $j('#parentId').val();
        const prIdIdx = window.location.href.indexOf('projectId=');
        if (prIdIdx >= 0) {
          const newUrl = window.location.href.replace(/projectId=.+?&/gm, "projectId=" + parentProjectId + "&");
          window.history.replaceState({ name: "TeamCity" }, "TeamCity", newUrl);
        } else {
          window.history.replaceState({ name: "TeamCity" }, "TeamCity", window.location.href + "&projectId=" + parentProjectId);
        }
        window.sessionStorage.setItem('createObject.repoUrl', $j('#url').val());
        window.sessionStorage.setItem('createObject.sshKeyName', newSshKeyName);
      },

      restoreUserData: function () {
        var isUrlOrKeyRestored = false;
        const userRepoUrl = window.sessionStorage.getItem('createObject.repoUrl');
        if (userRepoUrl) {
          $j('#url').val(userRepoUrl).change();
          window.sessionStorage.removeItem('createObject.repoUrl');
          isUrlOrKeyRestored = true;
        }

        const keyName = window.sessionStorage.getItem('createObject.sshKeyName');
        if (keyName) {
          $j('#teamcitySshKey').val(keyName).change();
          TeamCityAPI.Services.AlertService.successMessage('SSH key successfully uploaded and selected');
          window.sessionStorage.removeItem('createObject.sshKeyName');
          isUrlOrKeyRestored = true;
        } else {
          $j('#teamcitySshKey').val('').change();
        }

        if (isUrlOrKeyRestored) {
          this.selectAuthType('sshKeyAuthType');
        } else {
          this.selectAuthType('passwordAuthType');
        }
      },

      onKeySelect: function (encrypted) {
        if (encrypted) {
          $j('.sshKeyPassphrase').show();
          $j('#passphrase').attr("disabled", false);
        } else {
          $j('.sshKeyPassphrase').hide();
          $j('#passphrase').val('');
          $j('#passphrase').attr("disabled", true);
        }
      }
    });

    $j(document).ready(function() {
      <c:if test="${sshKeySupportEnabled}">
        $j('#url').on('keyup change', function (e) {
          const newVal = e.target.value;
          BS.CreateFromUrlForm.onUrlChange(newVal);
        });

        BS.CreateFromUrlForm.restoreUserData();
      </c:if>
    });
  </script>
  <bs:linkCSS>
    /css/admin/adminMain.css
  </bs:linkCSS>
  <style type="text/css">
    span.error {
      white-space: pre-wrap;
    }
  </style>
  <div id="container" class="clearfix" style="width:70%;">
    <form id="createFromUrlForm" action="<c:url value='/admin/createObjectFromUrl.html'/>" method="post" onsubmit="return BS.CreateFromUrlForm.submit()">
      <table class="runnerFormTable">
        <tr>
          <th><label for="parentId">Parent project:<l:star/></label></th>
          <td>
            <bs:projectsFilter name="parentId" id="parentId"
                               projectBeans="${createFromUrlBean.availableParents}"
                               selectedProjectExternalId="${createFromUrlBean.parentId}"
                               disableRoot="${createFromUrlBean.objectType == 'BUILD_TYPE'}"
                               onchange="BS.CreateFromUrlForm.onParentProjectChange(this.options[this.selectedIndex].value)"/>
            <span class="error" id="error_parentId"></span>
          </td>
        </tr>
        <tr>
          <th>
            <label for="url"><strong>Repository URL:<l:star/></strong></label>
          </th>
          <td>
            <forms:textField id="url" name="url" maxlength="256" className="longField" style="width: 40em;" value="${createFromUrlBean.url}"/>
            <jsp:include page="/admin/repositoryControls.html?projectId=${parentProject.externalId}"/>
          <span class="smallNote">A VCS repository URL. Supported formats: <strong>http(s)://, svn://, git://</strong>, etc. as well as URLs in Maven format.<bs:help file="Guess+Settings+from+Repository+URL"/></span>
            <span class="error" id="error_url"></span>
          </td>
        </tr>
        <c:if test="${sshKeySupportEnabled}">
          <tr>
            <th>
              <label for="authType"><strong>Authentication:</strong></label>
            </th>
            <td>
              <forms:select name="authType" id="authType_select" onchange="BS.CreateFromUrlForm.onAuthTypeChange(false);" className="longField">
                <forms:option value="passwordAuthType">Password / Access token</forms:option>
                <forms:option value="sshKeyAuthType">SSH key</forms:option>
              </forms:select>
            </td>
          </tr>
          <tr class="authTypeOption sshKeyAuthType">
            <th><label>SSH key:<l:star/></label></th>
            <td style="white-space: nowrap;">
              <span style="display: inline-block;">
                <admin:sshKeys projectId="${parentProject.externalId}" keySelectionCallback="BS.CreateFromUrlForm.onKeySelect"/>
                <span class="error" id="error_teamcitySshKey"></span>
              </span>
              <c:if test="${canEditProject}">
                <span style="margin: 8px;">
                  or
                </span>
                <span>
                  <forms:addButton id="createNewKey" onclick="BS.SshKeyUploadDialog.show(); return false">Upload SSH key</forms:addButton>
                </span>
              </c:if>
            </td>
          </tr>
          <tr class="authTypeOption sshKeyAuthType sshKeyPassphrase" style="display: none;">
            <th><label>SSH passphrase:</label></th>
            <td>
              <forms:passwordField id="passphrase" name="passphrase" className="longField"/>
              <span class="smallNote">Provide a passphrase for the encrypted SSH key.</span>
            </td>
          </tr>
        </c:if>
        <tr class="authTypeOption passwordAuthType">
          <th>
            <label for="username"><strong>Username: </strong></label>
          </th>
          <td>
            <forms:textField name="username" maxlength="80" className="longField" value="${createFromUrlBean.username}"/>
            <span class="error" id="error_username"></span>
            <span class="smallNote">Provide a username if access to the repository requires authentication.</span>
          </td>
        </tr>
        <tr class="authTypeOption passwordAuthType">
          <th>
            <label for="password"><strong>Password / access token: </strong></label>
          </th>
          <td>
            <forms:passwordField name="password" className="longField"/>
            <span class="error" id="error_password"></span>
            <span class="smallNote">Provide a password or a personal access token if access to the repository requires authentication.</span>
          </td>
        </tr>
      </table>

      <div class="saveButtonsBlock">
        <forms:submit name="createProjectFromUrl" label="Proceed"/>
        <c:if test="${not embedded}"><forms:cancel cameFromSupport="${createFromUrlBean.cameFromSupport}"/></c:if>
        <forms:saving/>

        <input type="hidden" name="objectType" value="${createFromUrlBean.objectType}"/>
        <input type="hidden" name="oauthProviderId" id="oauthProviderId" value=""/>
        <input type="hidden" name="usePermanentToken" id="usePermanentToken" value="" />
        <input type="hidden" name="publicKey" id="publicKey" value="<c:out value='<%=RSACipher.getHexEncodedPublicKey()%>'/>"/>
        <input type="hidden" name="cameFromUrl" value=""/>
        <input type="hidden" name="tokenType" id="tokenType" value="" />
      </div>
    </form>
  </div>
  <script type="text/javascript">
    if (BS.Repositories != null && !${readOnly}) {
      BS.Repositories.installControls($('url'), function(repoInfo, cre) {
        $('url').value = repoInfo.repositoryUrl;
        var prefillPassword = cre != null && (cre.permanentToken || cre.tokenType);

        if (cre != null) {
          $('username').value = cre.oauthLogin;

          $('oauthProviderId').value = cre.oauthProviderId;

          if (cre.permanentToken || cre.tokenType == "permanent") {
            $('usePermanentToken').value = 'true';
          } else {
            $('usePermanentToken').value = 'false';
          }

          $('tokenType').value = cre.tokenType;
        }

        if (prefillPassword) {
          $('password').value = '**********';
        }
      });
    }

    <c:forEach items="${createFromUrlBean.lastErrors.errors}" var="error">
    $j('#error_${error.id}').text('<bs:escapeForJs text="${error.message}"/>');
    </c:forEach>

    $('url').focus();
    $('createFromUrlForm').cameFromUrl.value = document.location.href.replace(/cameFromUrl=.*/, '');
    <c:if test="${readOnly}">
    $('createFromUrlForm').disable();
    </c:if>
  </script>
</c:set>

<c:choose>
  <c:when test="${not embedded}">
    <bs:page disableScrollingRestore="true">
      <jsp:attribute name="page_title">${title}</jsp:attribute>
      <jsp:attribute name="head_include">
        <script type="text/javascript">
          <admin:projectPathJS startProject="${parentProject}" startAdministration="${true}"/>

          BS.Navigation.items.push({
            title: '${title}',
            url: '${pageUrl}',
            selected: true
          });
        </script>
      </jsp:attribute>
      <jsp:attribute name="body_include">
        ${formContent}
      </jsp:attribute>
    </bs:page>
  </c:when>
  <c:otherwise>
    ${formContent}
  </c:otherwise>
</c:choose>
<bs:sshKeyUploadDialog customCloseAndRefresh="${myCloseAndRefreshAction}" projectId="${createFromUrlBean.parentId}"/>
