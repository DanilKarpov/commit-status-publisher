<%--@elvariable id="snippet" type="jetbrains.buildServer.web.openapi.PageExtension"--%>
<%@ include file="include-snippet.jsp" %>
<ext:includeExtension extension="${snippet}" isInHead="${false}" includeCSS="${true}" includeJS="${true}" includeContent="${true}"/>
<c:if test="${not empty param.iframe}">
  <div data-iframe-height></div>
  <base target="_top" />
</c:if>
