<%@ include file="/include-internal.jsp" %>

<bs:page>
  <jsp:attribute name="page_title">WebSocket Status</jsp:attribute>
  <jsp:attribute name="head_include">
        <script type="text/javascript">
          BS.Navigation.items = [
            {title: "WebSocket Diagnostics", selected:true}
          ];
        </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
      <div>Diagnostics information on Websocket communications of this page</div>
      <jsp:include page="admin/webSocketDiagnosticInfo.jsp"/>
  </jsp:attribute>
</bs:page>
