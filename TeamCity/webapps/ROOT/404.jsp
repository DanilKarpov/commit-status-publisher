<%@ page import="jetbrains.buildServer.web.util.WebUtil"
%><%@ page import="jetbrains.buildServer.controllers.Additional404Link"
%>
<%@ page import="org.springframework.http.HttpHeaders" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="util" uri="/WEB-INF/functions/util"
%><%@ taglib prefix="ufn" uri="/WEB-INF/functions/user"
%><c:set var="probablyBrowser" value='<%= WebUtil.isProbablyBrowser(request) %>'
/><c:set var="referrer" value='<%=request.getHeader(HttpHeaders.REFERER)%>'
/><c:set var="additionalLinks" value='<%=Additional404Link.getLinks(request)%>'
/><c:set var="message" value="${requestScope['javax.servlet.error.message']}"
/><!DOCTYPE html>
<html lang="en">
<head>
  <bs:pageMeta title="Not found"/>
  <title>Not found</title><c:if test="${probablyBrowser}">
    <style>
      body {
        font-family: system-ui, -apple-system, BlinkMacSystemFont,
          Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Droid Sans,
          Helvetica Neue, Arial, sans-serif;
      }

      .errorPage {
        padding-top: calc(50vh - 240px);
        text-align: center;
      }

      .errorPage__image {
        display: inline-block;
        height: 452px;
        width: 452px;
        vertical-align: -180px;
        margin: -32px -48px 0 -108px;
        background-size: contain;
        background-image: url('<c:url value="/img/errorPages/404.png"/>');
      }

      @media
        (-webkit-min-device-pixel-ratio: 2),
        (min-resolution: 2dppx) {

        .errorPage__image {
          background-image: url('<c:url value="/img/errorPages/404@2x.png"/>');
        }
      }

      .errorPage__text {
        display: inline-block;
        text-align: left;
        max-width: 452px;
      }

      .errorPage__code,
      .errorPage__title {
        padding: 0;
        font-size: 32px;
        line-height: 34px;
        color: var(--ring-text-color, #1f2326);
        margin: 0;
        font-weight: bold;
      }

      .errorPage__code {
        letter-spacing: 1.5px;
      }

      .errorPage__title {
        margin-bottom: 13px;
      }

      .errorPage__description {
        margin-top: 0;
        font-size: 14px;
        line-height: 22px;
      }
    </style></c:if>
  <bs:predefinedIntProps/>
  <bs:reactUi/>
  <c:if test="${not empty currentUser}">
    <script>
      ReactUI.setGlobalTheme("${ufn:getPreferredTheme(currentUser)}")
    </script>
  </c:if>
</head>
<body>
  <div class="errorPage">
    <div
        class="errorPage__image"
        title="Page not found"
    ></div><div class="errorPage__text">
      <h1 class="errorPage__code">404</h1>
      <h2 class="errorPage__title">
        <c:choose>
          <c:when test="${!message.startsWith('/')}">
            <c:out value="${message}"/>
          </c:when>
          <c:otherwise>
            The&nbsp;page is&nbsp;not&nbsp;found
          </c:otherwise>
        </c:choose>
      </h2>
      <p class="errorPage__description">
        Check that the&nbsp;URL is&nbsp;correct.
        <br/>
        <br/>
        <c:set var="escapedReferrer" value="${util:escapeFullUrl(referrer)}"/>
        <c:if test="${not empty escapedReferrer}">
          <a href="${escapedReferrer}" rel="noreferrer">Previous page</a>
          <br/>
        </c:if>
        <c:forEach var="link" items="${additionalLinks}">
          <c:url var="href" value="${link.href}"/>
          <a href="${href}" rel="noreferrer"><c:out value="${link.text}"/></a>
          <br/>
        </c:forEach>
        <a href="<c:url value='/'/>" rel="noreferrer">Overview page</a>
      </p>
    </div>
  </div>
</body>
</html>
