<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="newVersionBean" type="jetbrains.buildServer.controllers.autoUpdate.NewVersionBean" scope="request"/>
<jsp:useBean id="inlineMarkdownMessage" type="java.lang.Boolean" scope="request"/>

<c:if test="${not inlineMarkdownMessage}">
  <c:out value="${newVersionBean.displayName}"/> has been released<c:if test="${newVersionBean.autoUpdatePossible}"> and can be installed automatically</c:if>. View details on the <a href="<c:url value='/admin/admin.html?item=update'/>"/>Updates</a> page.
  <c:if test="${not empty newVersionBean.message}"><div><c:out value="${newVersionBean.message}"/></div></c:if>
  <c:if test="${not empty newVersionBean.markdownMessage}"><div style="display:none;visibility:hidden;" data-health-report-markdown-message><c:out value="${newVersionBean.markdownMessage}"/></div></c:if>
</c:if>

<c:if test="${inlineMarkdownMessage}">
  <c:if test="${empty newVersionBean.markdownMessage}">
    <c:out value="${newVersionBean.displayName}"/> has been released<c:if test="${newVersionBean.autoUpdatePossible}"> and can be installed automatically</c:if>. View details on the <a href="<c:url value='/admin/admin.html?item=update'/>"/>Updates</a> page.
    <c:if test="${not empty newVersionBean.message}"><div><c:out value="${newVersionBean.message}"/></div></c:if>
  </c:if>

  <c:if test="${not empty newVersionBean.markdownMessage}">
    <div data-health-report-react-markdown-container="${newVersionBean.buildNumber}"></div>
    <script type="application/javascript">
      (() => {
        const container = document.querySelector('[data-health-report-react-markdown-container="${newVersionBean.buildNumber}"]');
        ReactUI.renderMarkdown(container, {children: "<bs:escapeForJs forHTMLAttribute="true" text="${newVersionBean.markdownMessage}"/>"});
      })()
    </script>
  </c:if>
</c:if>