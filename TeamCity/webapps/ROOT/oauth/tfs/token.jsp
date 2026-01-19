<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<jsp:useBean id="serverUrl" type="java.lang.String" scope="request"/>
<c:set var="styles">
<bs:linkCSS>
  /css/forms.css
</bs:linkCSS>
</c:set>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To acquire the access token, TeamCity requires access to your Azure DevOps account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.TfsTokenContentUpdater = parent.TfsTokenContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/tfs/token.html?projectId=${project.externalId}&connectionId=${oauthProvider.id}&updateToken=true&showMode=${showMode}',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow}
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.TfsTokenContentUpdater();
            }
          } catch (e) {
          }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to Azure DevOps</forms:button>
        <forms:button onclick="window.TfsTokenContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.TfsTokenContentUpdater = function() {
          $j('#refreshProgress').show();
          $j('#signInButtons a').attr('disabled', true);
          if (refreshCurrentContainer) refreshCurrentContainer();
        }
      </script>
    </c:if>
  </c:when>
  <c:when test="${errorCode == 'requestFailed'}">
    ${styles}
    <div class="errorMessage"><c:out value="${errorMessage}"/></div>
  </c:when>
  <c:when test="${errorCode == 'tokenObtained'}">
    <bs:externalPage>
      <jsp:attribute name="page_title">Azure DevOps Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener) {
            if (window.opener.TfsTokenContentUpdater) {
              window.opener.TfsTokenContentUpdater();
            }
            window.close();
          }
        </script>
      </jsp:attribute>
      <jsp:attribute name="body_include">
        <div class="authenticated">
          Authentication successful! Please close this window and click "Refresh" button.
        </div>
      </jsp:attribute>
    </bs:externalPage>
  </c:when>
  <c:otherwise>
    <script type="text/javascript">
      if (window.getOAuthTokenCallback) {
        var cre = {
          oauthLogin: '<bs:forJs>${oauthUsername}</bs:forJs>',
          oauthProviderId: '<bs:forJs>${oauthProvider.id}</bs:forJs>',
          serverUrl: '<bs:forJs>${serverUrl}</bs:forJs>',
          permanentToken: true
        };
        window.getOAuthTokenCallback(cre);
      }
    </script>
  </c:otherwise>
</c:choose>
