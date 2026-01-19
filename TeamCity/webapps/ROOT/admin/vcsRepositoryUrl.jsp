<%@ taglib prefix="bs" tagdir="/WEB-INF/tags/" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<jsp:useBean id="parentProject" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<script type="text/javascript">
  $j(document).ready(function() {
    if (BS.Repositories != null) {
      BS.Repositories.installControls($('repositoryUrl'), function (repoInfo, cre) {
        $('repositoryUrl').value = repoInfo.repositoryUrl;
        var prefillPassword = cre != null && (cre.permanentToken || cre.tokenType);

        if (cre != null) {
          $('username').value = cre.oauthLogin;
          $('oauthProviderId').value = cre.oauthProviderId;
          $('tokenType').value = cre.tokenType;
          if (cre.tokenId) {
            $('tokenId').value = cre.tokenId;
          }
        }

        if (prefillPassword) {
          $('password').value = '**********';
        }
      });
    }
  });
</script>
<table class="runnerFormTable">
<l:settingsGroup title="Repository URL and Authentication">
<tr>
  <th>
    <label for="repositoryUrl"><strong>Repository URL:<l:star/></strong></label>
  </th>
  <td>
    <props:textProperty name="repositoryUrl" maxlength="256" className="longField disableBuildTypeParams" style="width: 40em;" onkeyup="BS.Util.syncValues(this, $('vcsRootName'))"/>
    <jsp:include page="/admin/repositoryControls.html?projectId=${parentProject.externalId}"/>
    <span class="smallNote">A VCS repository URL. Supported formats: <strong>http(s)://, svn://, git://</strong>, etc. as well as URLs in Maven format.<bs:help file="Guess+Settings+from+Repository+URL"/></span>
    <span class="error" id="error_repositoryUrl" style="white-space: pre"></span>
  </td>
</tr>
<tr>
  <th>
    <label for="username"><strong>Username: </strong></label>
  </th>
  <td>
    <props:textProperty name="username" maxlength="80" style="width: 20em;" className="disableBuildTypeParams"/>
    <span class="error" id="error_username"></span>
    <span class="smallNote">Provide username if access to the repository requires authentication</span>
  </td>
</tr>
<tr>
  <th>
    <label for="password"><strong>Password / access token: </strong></label>
  </th>
  <td>
    <props:passwordProperty name="password" style="width: 20em;" className="disableBuildTypeParams"/>
    <span class="error" id="error_password"></span>
    <span class="smallNote">Provide password if access to the repository requires authentication</span>
  </td>
</tr>
</l:settingsGroup>
</table>
<props:hiddenProperty name="oauthProviderId" id="oauthProviderId" value=""/>
<props:hiddenProperty name="tokenType" id="tokenType" value=""/>
<props:hiddenProperty name="tokenId" id="tokenId" value=""/>
