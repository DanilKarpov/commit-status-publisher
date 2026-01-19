<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ include file="/include-internal.jsp"%>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="tokenId" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="teamcityName" type="java.lang.String"--%>
<%--@elvariable id="teamcityUsername" type="java.lang.String"--%>
<%--@elvariable id="acquiredNew" type="java.lang.Boolean"--%>
<%--@elvariable id="warning" type="java.lang.String"--%>
<%--@elvariable id="newTokenRequestParams" type="java.lang.String"--%>
<%--@elvariable id="reuseWindow" type="java.lang.Boolean"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>

<c:url value="${oauthProvider.oauthProvider.tokenPopupPath}" var="getTokenPage"/>

<c:set var="styles">
<bs:linkCSS>
  /css/forms.css
</bs:linkCSS>
</c:set>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired' and not reuseWindow}">
    ${styles}
    <div>
      To acquire the access token TeamCity requires access to your ${oauthProvider.oauthProvider.displayName} account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.TokenContentUpdater = parent.TokenContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          '${getTokenPage}<bs:escapeForJs forHTMLAttribute="true" text="${newTokenRequestParams}"/>',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow}
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.TokenContentUpdater();
            }
          } catch (e) { }
        }, 1000);
        return false;
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in</forms:button>
        <forms:button onclick="window.TokenContentUpdater(); return false;">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.TokenContentUpdater = function() {
          $j('#refreshProgress').show();
          $j('#signInButtons a').attr('disabled', true);
          if (refreshCurrentContainer) refreshCurrentContainer();
        }
      </script>
    </c:if>
  </c:when>

  <c:when test="${errorCode == 'requestFailed' and not reuseWindow}">
    ${styles}
    <div class="errorMessage"><c:out value="${errorMessage}"/></div>
  </c:when>

  <c:when test="${errorCode == 'tokenObtained'}">
    <bs:externalPage>
      <jsp:attribute name="page_title">Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener && window.opener.parent.TokenContentUpdater) {
            window.opener.parent.TokenContentUpdater();
          }
          window.close();
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
      {
        let res = {
          oauthLogin: '<bs:forJs>${oauthUsername}</bs:forJs>',
          oauthProviderId: '<bs:forJs>${oauthProvider.id}</bs:forJs>',
          permanentToken: true,
          tokenId: '<bs:forJs>${tokenId}</bs:forJs>',
          teamcityName: '<bs:forJs>${teamcityName}</bs:forJs>',
          teamcityUsername: '<bs:forJs>${teamcityUsername}</bs:forJs>',
          connectionId: '<bs:forJs>${oauthProvider.id}</bs:forJs>'
        };
        if ('${acquiredNew}' == 'true') {
          res["acquiredNew"] = true;
        }

        if(!("${warning}".trim() === "")) {
          res["warning"] = '<bs:forJs>${warning}</bs:forJs>';
        }

        if ('${errorCode}' === 'requestFailed') {
          res["errorMessage"] = '<bs:forJs>${errorMessage}</bs:forJs>';
        }

        var copy={};
        Object.assign(copy, res);

        const tokenCallback = window.getOAuthTokenCallback ?? window.opener?.getOAuthTokenCallback;
        if (tokenCallback) {
          tokenCallback(copy);
        } else {
          console.warn("Unable to find window.getOAuthTokenCallback in current window or its opener. Have we crossed origins?");
          // this will be picked up by polling from the parent window, see tokenObtainer.tag
          const key = 'obtainTokenResult-<bs:forJs>${project.externalId}</bs:forJs>-<bs:forJs>${oauthProvider.id}</bs:forJs>';
          window.localStorage.setItem(key, JSON.stringify(res));
          // need to close ourselves as the link to the parent has been broken
          window.close();
        }
      }
    </script>
  </c:otherwise>
</c:choose>
