<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
  taglib prefix="ext" tagdir="/WEB-INF/tags/ext"%><%@
  taglib prefix="bs" tagdir="/WEB-INF/tags"%>

<c:if test="${param.embedded}">
  <bs:linkScript>
    /js/iframeResizer/iframeResizer.contentWindow.js
  </bs:linkScript>
</c:if>

<ext:includeExtensions placeId="<%=PlaceId.PROJECT_STATS_FRAGMENT%>" includeReactExtensions="true"/>
<div id="nothingMessage" style="display: none; margin-bottom: 16px">
  There are no available charts for this project. Please read the <bs:helpLink file="Custom+Chart" anchor="AddingCustomCharts">documentation</bs:helpLink> on adding custom project charts.
</div>

<script type="text/javascript">
  $j(function() {
    if ($j("div.GraphContainer").length == 0) {
      $j('#nothingMessage').show();
    }
  });
</script>
