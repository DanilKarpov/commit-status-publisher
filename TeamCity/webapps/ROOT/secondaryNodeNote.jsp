<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<jsp:useBean id="mainServerRootUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="mainServerUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="nodeId" scope="request" type="java.lang.String"/>

<style type="text/css">
  .secondaryNodeNote {
    position: relative;
    z-index: 1;
    border-bottom: 1px solid #b25c00;
    padding: 4px 0 4px 0;
    background: var(--tc-classic-highlight-color, #ffc);
    color: var(--ring-text-color, #1f2326);
    text-align: center;
    width: 100%;
  }
</style>
<div class="secondaryNodeNote" style="display: none">
  ${intprop:getProperty('teamcity.internal.secondaryNode.headerNote', 'This is a secondary TeamCity node. Write operations are disabled on this server.')}
  <c:if test="${not empty mainServerUrl}"> <a id="secondaryNodeLink" href="${mainServerUrl}"> Open the current page</a> on the main TeamCity server.</c:if>
</div>

<script type="application/javascript">
  (function() {
    $j('.secondaryNodeNote').prependTo("body").sticky({topSpacing: 0, zIndex: 1000, widthFromWrapper: false});
    $j('.secondaryNodeNote').show();

    <c:if test="${not empty mainServerUrl and not empty mainServerRootUrl}">
      if (window.ReactUI) {
        var link = document.getElementById('secondaryNodeLink');
        var mainServerRootUrl = '${mainServerRootUrl}'.replace(/\/$/, '');
        ReactUI.history.listen(function() {
          var path = location.href.slice(base_uri.length).replace(/^\//, '');
          link.href = mainServerRootUrl + '/' + path;
        });
      }
    </c:if>
  })();
</script>


