<%@include file="/include-internal.jsp"%>
<c:set var="title" value="License Agreement"/>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      .agreementPageWrapper {
        padding: 10px;
      }
    </style>
    <script>
      ReactUI.setGlobalTheme();
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="agreementPageWrapper">
      <jsp:include page="/license/agreement.jsp"/>
    </div>
  </jsp:attribute>
</bs:externalPage>
