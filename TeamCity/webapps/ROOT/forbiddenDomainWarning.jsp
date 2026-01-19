<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="domainProtectionServerUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="domainProtectionShowWarning" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="domainProtectionWarningMessage" scope="request" type="java.lang.String"/>

<c:if test="${domainProtectionShowWarning}">
  <style type="text/css">
      .forbiddenDomainWarning {
          border-bottom: 1px solid #b25c00;
          padding: 4px 0 4px 0;
          background: var(--tc-classic-highlight-color, #ffc);
          color: var(--ring-text-color, #1f2326);
          text-align: center;
          width: 100%;
      }
  </style>

  <div class="forbiddenDomainWarning" style="display: none">
      ${domainProtectionWarningMessage}.
    <c:if test="${not empty domainProtectionServerUrl}"> <a id="forbiddenDomainWarningLink" href="${domainProtectionServerUrl}"> Open the current page</a> on the main TeamCity server.</c:if> <bs:help file="Artifacts+Domain+Isolation"/>
  </div>

  <script type="application/javascript">
    (function () {
      $j('.forbiddenDomainWarning').prependTo("body").sticky({topSpacing: 0, zIndex: 1000, widthFromWrapper: false});
      $j('.forbiddenDomainWarning').show();

      <c:if test="${not empty domainProtectionServerUrl}">
      if (window.ReactUI) {
        var link = document.getElementById('forbiddenDomainWarningLink');
        var mainServerRootUrl = '${domainProtectionServerUrl}'.replace(/\/$/, '');
        ReactUI.history.listen(function () {
          var path = location.href.slice(base_uri.length).replace(/^\//, '');
          link.href = mainServerRootUrl + '/' + path;
        });
      }
      </c:if>
    })();
  </script>
</c:if>


